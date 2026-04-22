#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $testEnv = Initialize-IntegrationEnvironment
        $script:SkipFilterTests = [string]::IsNullOrEmpty($testEnv.TestFilter)
    }
}

InModuleScope JiraPS {
    Describe "JQL Search" -Tag 'Integration', 'Smoke' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Describe "Get-JiraIssue -Query" {
            Context "Basic JQL Queries" {
                It "searches for issues using JQL" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $jql = "project = $($fixtures.TestProject)"

                    $results = Get-JiraIssue -Query $jql

                    $results | Should -Not -BeNullOrEmpty
                }

                It "returns issue objects" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $jql = "project = $($fixtures.TestProject)"

                    $results = Get-JiraIssue -Query $jql

                    @($results)[0].PSObject.TypeNames[0] | Should -Be 'JiraPS.Issue'
                }

                It "searches for specific issue by key" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $jql = "key = $($fixtures.TestIssue)"

                    $results = Get-JiraIssue -Query $jql

                    @($results).Count | Should -Be 1
                    @($results)[0].Key | Should -Be $fixtures.TestIssue
                }
            }

            Context "JQL with Operators" {
                It "supports AND operator" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $jql = "project = $($fixtures.TestProject) AND status != Done"

                    # Verify the query executes and returns valid results (may be empty)
                    $results = Get-JiraIssue -Query $jql -ErrorAction Stop
                    # Results should be null/empty or valid issue objects
                    if ($results) {
                        @($results)[0].Key | Should -Match '^\w+-\d+$'
                    }
                }

                It "supports OR operator" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    # OR with a non-existent project should still return results from the valid project
                    $jql = "project = $($fixtures.TestProject) OR project = NONEXISTENT"

                    $results = Get-JiraIssue -Query $jql -ErrorAction Stop
                    # Should return at least the test issue from TestProject
                    $results | Should -Not -BeNullOrEmpty -Because "test project should have issues"
                    @($results)[0].Project.Key | Should -Be $fixtures.TestProject
                }

                It "supports ORDER BY" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $jql = "project = $($fixtures.TestProject) ORDER BY created DESC"

                    $results = Get-JiraIssue -Query $jql

                    $results | Should -Not -BeNullOrEmpty
                }
            }

            Context "Pagination" {
                # Get-JiraIssue uses [CmdletBinding(SupportsPaging)], which exposes the
                # standard PowerShell paging parameters -First / -Skip / -IncludeTotalCount.
                # There is no -MaxResults or -StartIndex parameter.
                It "supports -First parameter" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $jql = "project = $($fixtures.TestProject)"

                    $results = Get-JiraIssue -Query $jql -First 1

                    @($results).Count | Should -BeLessOrEqual 1
                }

                It "supports -Skip parameter" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    # Skip on Jira Cloud - the startAt parameter doesn't work reliably
                    # with small result sets on Cloud instances
                    if ($fixtures.CloudUrl -match 'atlassian\.net') {
                        Set-ItResult -Skipped -Because "Skip-based pagination is unreliable on Jira Cloud"
                        return
                    }

                    $jql = "project = $($fixtures.TestProject) ORDER BY key ASC"

                    $firstPage = Get-JiraIssue -Query $jql -First 1 -Skip 0
                    $secondPage = Get-JiraIssue -Query $jql -First 1 -Skip 1

                    # If there's a second page with results, verify it's different from first
                    if ($secondPage -and @($secondPage).Count -gt 0) {
                        @($firstPage)[0].Key | Should -Not -Be @($secondPage)[0].Key
                    }
                    else {
                        # Only one issue in project - just verify first page works
                        $firstPage | Should -Not -BeNullOrEmpty
                    }
                }

                It "supports -PageSize for automatic paging" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $jql = "project = $($fixtures.TestProject)"

                    { Get-JiraIssue -Query $jql -PageSize 10 } | Should -Not -Throw
                }
            }

            Context "Field Selection in Search" {
                It "returns specified fields only" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $jql = "key = $($fixtures.TestIssue)"

                    $results = Get-JiraIssue -Query $jql -Fields "summary", "status"

                    @($results)[0].Summary | Should -Not -BeNullOrEmpty
                }
            }

            Context "Cloud API v3 Behavior" {
                It "returns description as string (ADF converted)" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $jql = "key = $($fixtures.TestIssue)"

                    $results = Get-JiraIssue -Query $jql

                    @($results)[0].Description | Should -BeOfType [string]
                }
            }

            Context "Error Handling" {
                It "fails with invalid JQL syntax" {
                    $invalidJql = "this is not valid JQL syntax !!!"

                    { Get-JiraIssue -Query $invalidJql -ErrorAction Stop } |
                        Should -Throw
                }

                It "returns empty for JQL with no matches" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $jql = "project = $($fixtures.TestProject) AND summary ~ 'NONEXISTENT_UNIQUE_STRING_12345'"

                    $results = Get-JiraIssue -Query $jql

                    @($results).Count | Should -Be 0
                }
            }
        }

        Describe "Get-JiraIssue -Filter" {
            Context "Filter-based Search" {
                It "retrieves issues using a saved filter ID" {
                    if ([string]::IsNullOrEmpty($fixtures.TestFilter)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_FILTER not configured"
                        return
                    }
                    # Limit to 1 result to avoid long pagination on filters with many matches
                    $results = Get-JiraIssue -Filter $fixtures.TestFilter -First 1

                    $results | Should -BeOfType [PSCustomObject]
                }
            }
        }
    }
}
