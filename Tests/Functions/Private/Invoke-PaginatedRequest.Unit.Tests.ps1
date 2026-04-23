#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

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
