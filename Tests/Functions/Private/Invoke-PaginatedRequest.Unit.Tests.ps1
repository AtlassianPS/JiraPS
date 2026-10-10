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
