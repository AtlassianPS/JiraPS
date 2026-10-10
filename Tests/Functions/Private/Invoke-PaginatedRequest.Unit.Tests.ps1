#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Invoke-PaginatedRequest" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            #endregion Definitions
        }

        Describe "Token pagination" {
            BeforeAll {
                $script:tokenResponse = [PSCustomObject]@{
                    issues        = @([PSCustomObject]@{ key = 'TEST-1' })
                    nextPageToken = 'page-2'
                    isLast        = $false
                }
                Mock Invoke-JiraMethod -ModuleName JiraPS {
                    [PSCustomObject]@{
                        issues = @([PSCustomObject]@{ key = 'TEST-2' })
                        isLast = $true
                    }
                }
            }

            It "follows tokens even when a page has fewer items than the default page size" {
                $result = @(Invoke-PaginatedRequest -URI "$jiraServer/rest/api/3/search/jql" -Response $tokenResponse)

                ($result.key -join ',') | Should -Be 'TEST-1,TEST-2'
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $GetParameter.nextPageToken -eq 'page-2' -and -not $GetParameter.ContainsKey('startAt')
                }
            }

            It "stops before requesting another token page when First is satisfied" {
                $result = @(Invoke-PaginatedRequest -URI "$jiraServer/rest/api/3/search/jql" -Response $tokenResponse -First 1)

                ($result.key -join ',') | Should -Be 'TEST-1'
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 0 -Scope It
            }
        }

        Describe "Short final offset page" -ForEach @(
            @{ apiVersion = 2; container = 'values'; hasTotal = $true }
            @{ apiVersion = 3; container = 'fields'; hasTotal = $true }
            @{ apiVersion = 3; container = 'fields'; hasTotal = $false }
        ) {
            BeforeAll {
                $script:shortPageContainer = $container
                $script:shortPageHasTotal = $hasTotal
                $script:shortPageResponse = [PSCustomObject]@{
                    startAt = 0; maxResults = 2
                    $container = @([PSCustomObject]@{ id = 'A' }, [PSCustomObject]@{ id = 'B' })
                }
                if ($hasTotal) { $shortPageResponse | Add-Member -NotePropertyName total -NotePropertyValue 3 }
                Mock Invoke-JiraMethod -ModuleName JiraPS {
                    if ($GetParameter.startAt -ne 2) { throw "Unexpected offset: $($GetParameter.startAt)" }
                    $page = [PSCustomObject]@{
                        startAt = 2; maxResults = 2
                        $shortPageContainer = @([PSCustomObject]@{ id = 'C' })
                    }
                    if ($shortPageHasTotal) { $page | Add-Member -NotePropertyName total -NotePropertyValue 3 }
                    $page
                }
            }

            It "returns the short final page on v<apiVersion> with total=<hasTotal> without First" {
                $result = @(Invoke-PaginatedRequest -URI "$jiraServer/rest/api/$apiVersion/issue/createmeta/1/issuetypes/2" -Response $shortPageResponse)

                ($result.id -join ',') | Should -Be 'A,B,C'
                $result | Should -HaveCount 3
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $GetParameter.startAt -eq 2 -and -not $GetParameter.ContainsKey('nextPageToken')
                }
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
        }

        Describe "IncludeTotalCount with offset pagination" {
            BeforeAll {
                $script:countItems = @('A', 'B', 'C', 'D', 'E') | ForEach-Object { [PSCustomObject]@{ id = $_ } }
                Mock Invoke-JiraMethod -ModuleName JiraPS {
                    $pageSize = 2
                    if ($GetParameter.ContainsKey('maxResults')) { $pageSize = [Math]::Min(2, [int]$GetParameter.maxResults) }
                    [PSCustomObject]@{
                        startAt = $GetParameter.startAt; maxResults = $pageSize; total = 5
                        values = @($countItems | Select-Object -Skip $GetParameter.startAt -First $pageSize)
                    }
                }
            }

            It "reports the full server total before items with First=<first> and Skip=<offset>" -ForEach @(
                @{ first = [uint64]::MaxValue; offset = 0; ids = 'A,B,C,D,E'; requests = 2 }
                @{ first = 3; offset = 0; ids = 'A,B,C'; requests = 1 }
                @{ first = [uint64]::MaxValue; offset = 1; ids = 'B,C,D,E'; requests = 1 }
                @{ first = 3; offset = 1; ids = 'B,C,D'; requests = 1 }
                @{ first = 1; offset = 1; ids = 'B'; requests = 0 }
            ) {
                $response = [PSCustomObject]@{
                    startAt = $offset; maxResults = 2; total = 5
                    values = @($countItems | Select-Object -Skip $offset -First 2)
                }
                $result = @(Invoke-PaginatedRequest -URI "$jiraServer/rest/api/2/search" -Response $response -IncludeTotalCount -First $first -Skip $offset)

                $result[0] | Should -BeOfType ([uint64])
                $result[0] | Should -Be 5
                $result[0].Accuracy | Should -Be 1.0
                (@($result | Select-Object -Skip 1).id -join ',') | Should -Be $ids
                @($result | Where-Object { $_ -is [uint64] }) | Should -HaveCount 1
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times $requests -Scope It
            }
        }

        Describe "Three token pages" {
            BeforeAll {
                $script:threeTokenResponse = [PSCustomObject]@{
                    issues        = @([PSCustomObject]@{ key = 'A' }, [PSCustomObject]@{ key = 'B' })
                    nextPageToken = 'page-2'
                }
                Mock Invoke-JiraMethod -ModuleName JiraPS {
                    $requestedTokens.Add([string]$GetParameter.nextPageToken)
                    switch ($GetParameter.nextPageToken) {
                        'page-2' {
                            [PSCustomObject]@{
                                issues        = @([PSCustomObject]@{ key = 'C' }, [PSCustomObject]@{ key = 'D' })
                                nextPageToken = 'page-3'
                            }
                        }
                        'page-3' { [PSCustomObject]@{ issues = @([PSCustomObject]@{ key = 'E' }) } }
                        default { throw "Unexpected token: $($GetParameter.nextPageToken)" }
                    }
                }
            }

            BeforeEach {
                $script:requestedTokens = [System.Collections.Generic.List[string]]::new()
            }

            It "returns every item and stops when the third page omits its continuation token" {
                $result = @(Invoke-PaginatedRequest -URI "$jiraServer/rest/api/3/search/jql" -Response $threeTokenResponse)

                ($result.key -join ',') | Should -Be 'A,B,C,D,E'
                $result | Should -HaveCount 5
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
                ($requestedTokens -join ',') | Should -Be 'page-2,page-3'
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It -ParameterFilter {
                    -not $GetParameter.ContainsKey('startAt')
                }
            }

            It "trims a token page when First falls inside the second page" {
                $result = @(Invoke-PaginatedRequest -URI "$jiraServer/rest/api/3/search/jql" -Response $threeTokenResponse -First 3)

                ($result.key -join ',') | Should -Be 'A,B,C'
                $result | Should -HaveCount 3
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $GetParameter.nextPageToken -eq 'page-2'
                }
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "reports an unknown total before limited token results when the API provides no total" {
                $result = @(Invoke-PaginatedRequest -URI "$jiraServer/rest/api/3/search/jql" -Response $threeTokenResponse -First 3 -IncludeTotalCount)

                $result[0] | Should -BeOfType ([uint64])
                $result[0].Accuracy | Should -Be 0.0
                (@($result | Select-Object -Skip 1).key -join ',') | Should -Be 'A,B,C'
                @($result | Where-Object { $_ -is [uint64] }) | Should -HaveCount 1
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
        }

        Describe "Null Response Handling" {
            # When Invoke-JiraMethod returns null during pagination (auth failure,
            # server error, etc.), the function should stop gracefully with a warning
            # instead of crashing with "Cannot bind argument to parameter 'InputObject'".

            BeforeAll {
                # Initial response with results
                $script:initialResponse = [PSCustomObject]@{
                    issues     = @(
                        [PSCustomObject]@{ key = 'TEST-1' }
                        [PSCustomObject]@{ key = 'TEST-2' }
                    )
                    startAt    = 0
                    maxResults = 2
                    total      = 10
                }

                # Mock Invoke-JiraMethod to return null on second call (simulating failure)
                $script:callCount = 0
                Mock Invoke-JiraMethod -ModuleName JiraPS {
                    $script:callCount++
                    if ($script:callCount -eq 1) {
                        return $null  # Simulates auth failure or server error
                    }
                    return $null
                }
            }

            BeforeEach {
                $script:callCount = 0
            }

            It "does not throw when Invoke-JiraMethod returns null" {
                $params = @{
                    URI      = "$jiraServer/rest/api/2/search"
                    Method   = 'GET'
                    Response = $initialResponse
                }

                { Invoke-PaginatedRequest @params -WarningAction SilentlyContinue } | Should -Not -Throw
            }

            It "writes a warning when null response is received" {
                $params = @{
                    URI      = "$jiraServer/rest/api/2/search"
                    Method   = 'GET'
                    Response = $initialResponse
                }

                # Capture warnings using -WarningVariable (no $ prefix for target variable)
                $null = Invoke-PaginatedRequest @params -WarningVariable capturedWarnings

                $capturedWarnings | Should -Not -BeNullOrEmpty
                $capturedWarnings | Should -Match 'null response'
            }

            It "stops pagination and returns collected results" {
                # First page has 2 issues, second call returns null
                $script:pageCallCount = 0
                Mock Invoke-JiraMethod -ModuleName JiraPS {
                    $script:pageCallCount++
                    if ($script:pageCallCount -gt 1) {
                        return $null
                    }
                    return [PSCustomObject]@{
                        issues     = @([PSCustomObject]@{ key = "TEST-$script:pageCallCount" })
                        startAt    = 0
                        maxResults = 1
                        total      = 5
                    }
                }

                $params = @{
                    URI      = "$jiraServer/rest/api/2/search"
                    Method   = 'GET'
                    Response = [PSCustomObject]@{
                        issues     = @([PSCustomObject]@{ key = 'TEST-0' })
                        startAt    = 0
                        maxResults = 1
                        total      = 5
                    }
                }

                $result = Invoke-PaginatedRequest @params -WarningAction SilentlyContinue

                # Should have the initial result from Response parameter
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
}
