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

        Describe 'User pagination protocols' {
            It 'pages bare user arrays using server offsets without extra user lookups' {
                Mock Invoke-JiraRequest { [PSCustomObject]@{ name = 'third' } }
                $response = @([PSCustomObject]@{ name = 'first' }, [PSCustomObject]@{ name = 'second' })
                $result = @(Invoke-PaginatedRequest -Uri "$jiraServer/rest/api/2/user/search" -Response $response -PageSize 2 -GetParameter @{ maxResults = 2; startAt = 3 } -First 3)
                $result.name | Should -Be @('first', 'second', 'third')
                Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter {
                    $GetParameter.startAt -eq 5 -and $GetParameter.maxResults -eq 1
                }
            }

            It 'follows Data Center cursors and applies Skip locally' {
                Mock Invoke-JiraRequest {
                    [PSCustomObject]@{ values = @([PSCustomObject]@{ name = 'third' }, [PSCustomObject]@{ name = 'fourth' }); isLast = $true }
                }
                $response = [PSCustomObject]@{
                    values     = @([PSCustomObject]@{ name = 'first' }, [PSCustomObject]@{ name = 'second' })
                    nextCursor = 'opaque+cursor'
                    isLast     = $false
                }
                $result = @(Invoke-PaginatedRequest -Uri "$jiraServer/rest/api/2/user/list" -Response $response -PageSize 2 -Skip 3 -First 1 -IncludeTotalCount)
                $result.Count | Should -Be 2
                $result[0].ToString() | Should -Match 'Unknown'
                $result[1].name | Should -Be 'fourth'
                Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter {
                    $GetParameter.cursor -eq 'opaque+cursor' -and -not $GetParameter.ContainsKey('startAt')
                }
            }

            It 'stops repeated Data Center cursors even when pages are empty' {
                $response = [PSCustomObject]@{ values = @(); nextCursor = 'same'; isLast = $false }
                Mock Invoke-JiraRequest { [PSCustomObject]@{ values = @(); nextCursor = 'same'; isLast = $false } }
                { Invoke-PaginatedRequest -Uri "$jiraServer/rest/api/2/user/list" -Response $response } |
                    Should -Throw '*repeated a pagination token*'
                Should -Invoke Invoke-JiraRequest -Exactly 1
            }

            It 'returns no items for an empty user-search array' {
                Mock Invoke-JiraRequest { throw 'Unexpected continuation' }
                @(Invoke-PaginatedRequest -Uri "$jiraServer/rest/api/3/user/search" -Response @()) | Should -HaveCount 0
                Should -Invoke Invoke-JiraRequest -Exactly 0
            }
        }

        Describe "Token pagination" {
            BeforeAll {
                $script:tokenResponse = [PSCustomObject]@{
                    issues        = @([PSCustomObject]@{ key = 'TEST-1' })
                    nextPageToken = 'page-2'
                    isLast        = $false
                }
                Mock Invoke-JiraRequest -ModuleName JiraPS {
                    [PSCustomObject]@{
                        issues = @([PSCustomObject]@{ key = 'TEST-2' })
                        isLast = $true
                    }
                }
            }

            It "follows tokens even when a page has fewer items than the default page size" {
                $result = @(Invoke-PaginatedRequest -URI "$jiraServer/rest/api/3/search/jql" -Response $tokenResponse)

                ($result.key -join ',') | Should -Be 'TEST-1,TEST-2'
                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $GetParameter.nextPageToken -eq 'page-2' -and -not $GetParameter.ContainsKey('startAt')
                }
            }

            It "stops before requesting another token page when First is satisfied" {
                $result = @(Invoke-PaginatedRequest -URI "$jiraServer/rest/api/3/search/jql" -Response $tokenResponse -First 1)

                ($result.key -join ',') | Should -Be 'TEST-1'
                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 0 -Scope It
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
                Mock Invoke-JiraRequest -ModuleName JiraPS {
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
                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $GetParameter.startAt -eq 2 -and -not $GetParameter.ContainsKey('nextPageToken')
                }
                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
        }

        Describe "IncludeTotalCount with offset pagination" {
            BeforeAll {
                $script:countItems = @('A', 'B', 'C', 'D', 'E') | ForEach-Object { [PSCustomObject]@{ id = $_ } }
                Mock Invoke-JiraRequest -ModuleName JiraPS {
                    $pageSize = if ($GetParameter.ContainsKey('maxResults')) { [Math]::Min(2, [int]$GetParameter.maxResults) }
                    else { 2 }
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
                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times $requests -Scope It
            }
        }

        Describe "Three token pages" {
            BeforeAll {
                $script:threeTokenResponse = [PSCustomObject]@{
                    issues        = @([PSCustomObject]@{ key = 'A' }, [PSCustomObject]@{ key = 'B' })
                    nextPageToken = 'page-2'
                }
                Mock Invoke-JiraRequest -ModuleName JiraPS {
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
                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 2 -Scope It
                ($requestedTokens -join ',') | Should -Be 'page-2,page-3'
                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 2 -Scope It -ParameterFilter {
                    -not $GetParameter.ContainsKey('startAt')
                }
            }

            It "trims a token page when First falls inside the second page" {
                $result = @(Invoke-PaginatedRequest -URI "$jiraServer/rest/api/3/search/jql" -Response $threeTokenResponse -First 3)

                ($result.key -join ',') | Should -Be 'A,B,C'
                $result | Should -HaveCount 3
                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $GetParameter.nextPageToken -eq 'page-2'
                }
                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "reports an unknown total before limited token results when the API provides no total" {
                $result = @(Invoke-PaginatedRequest -URI "$jiraServer/rest/api/3/search/jql" -Response $threeTokenResponse -First 3 -IncludeTotalCount)

                $result[0] | Should -BeOfType ([uint64])
                $result[0].Accuracy | Should -Be 0.0
                (@($result | Select-Object -Skip 1).key -join ',') | Should -Be 'A,B,C'
                @($result | Where-Object { $_ -is [uint64] }) | Should -HaveCount 1
                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
        }

        Describe 'Per-page retry budget' {
            It 'retries the next <Protocol> page after the first page uses its full retry budget' -ForEach @(
                @{
                    Protocol    = 'offset'
                    Resource    = '/rest/api/2/search'
                    InitialPage = '{"issues":[{"key":"TEST-1"}],"startAt":0,"maxResults":1,"total":2}'
                    FinalPage   = '{"issues":[{"key":"TEST-2"}],"startAt":1,"maxResults":1,"total":2}'
                }
                @{
                    Protocol    = 'token'
                    Resource    = '/rest/api/3/search/jql'
                    InitialPage = '{"issues":[{"key":"TEST-1"}],"nextPageToken":"page-2"}'
                    FinalPage   = '{"issues":[{"key":"TEST-2"}],"isLast":true}'
                }
            ) {
                $script:retryPageAttempts = @{ first = 0; second = 0 }
                $script:retryInitialPage = $InitialPage
                $script:retryFinalPage = $FinalPage
                Mock Set-TlsLevel {}
                Mock Resolve-DefaultParameterValue { @{} }
                Mock Start-Sleep {}
                Mock Invoke-WebRequest {
                    $query = [Web.HttpUtility]::ParseQueryString($Uri.Query)
                    $page = if ($query['startAt'] -eq '1' -or $query['nextPageToken']) { 'second' } else { 'first' }
                    $script:retryPageAttempts[$page]++
                    $retryLimit = if ($page -eq 'first') { 3 } else { 1 }
                    $retry = $script:retryPageAttempts[$page] -le $retryLimit
                    $content = if ($retry) { '{"errorMessages":["Temporarily unavailable"]}' }
                    elseif ($page -eq 'first') { $script:retryInitialPage }
                    else { $script:retryFinalPage }
                    [PSCustomObject]@{
                        StatusCode       = if ($retry) { [Net.HttpStatusCode]::ServiceUnavailable } else { [Net.HttpStatusCode]::OK }
                        Content          = $content
                        RawContentStream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($content))
                        Headers          = @{ 'Retry-After' = '1' }
                    }
                }

                $result = @(Invoke-JiraRequest -Uri $Resource -Paging -PageSize 1 -WarningAction SilentlyContinue -ErrorAction Stop)

                $result.key | Should -Be @('TEST-1', 'TEST-2')
                $retryPageAttempts.first | Should -Be 4
                $retryPageAttempts.second | Should -Be 2
                Should -Invoke Start-Sleep -Exactly 4
            }
        }

        Describe "Null Response Handling" {
            # When Invoke-JiraRequest returns null during pagination (auth failure,
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

                Mock Invoke-JiraRequest -ModuleName JiraPS { $null }
            }

            It 'returns the collected items and warns once when the next page is null' {
                $params = @{
                    URI      = "$jiraServer/rest/api/2/search"
                    Method   = 'GET'
                    Response = $initialResponse
                }

                $result = @(Invoke-PaginatedRequest @params -WarningVariable capturedWarnings -WarningAction SilentlyContinue)

                $result.key | Should -Be @('TEST-1', 'TEST-2')
                $capturedWarnings | Should -HaveCount 1
                $capturedWarnings | Should -Match 'null response'
                Should -Invoke Invoke-JiraRequest -Exactly -Times 1
            }
        }
    }
}
