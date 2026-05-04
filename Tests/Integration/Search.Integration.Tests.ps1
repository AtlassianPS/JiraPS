#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $testEnv = Initialize-IntegrationEnvironment
        $script:SkipFilterTests = [string]::IsNullOrEmpty($testEnv.TestFilter)
    }
}

InModuleScope JiraPS {
    Describe "JQL Search" -Tag 'Integration', 'Smoke', 'Server', 'Cloud' -Skip:$Skip {
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
                    # Anchor the project query to the fixture issue when present.
                    # Fresh Jira DC boots can briefly return an empty project-only
                    # search while indexing catches up, even though JIRA_TEST_ISSUE
                    # is already resolvable and belongs to the same project.
                    $jql = if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        "project = $($fixtures.TestProject)"
                    }
                    else {
                        "project = $($fixtures.TestProject) AND key = $($fixtures.TestIssue)"
                    }

                    $results = Get-JiraIssue -Query $jql

                    $results | Should -Not -BeNullOrEmpty
                    if ($fixtures.TestIssue) {
                        @($results).Key | Should -Contain $fixtures.TestIssue
                    }
                }

                It "returns issue objects" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $jql = if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        "project = $($fixtures.TestProject)"
                    }
                    else {
                        "project = $($fixtures.TestProject) AND key = $($fixtures.TestIssue)"
                    }

                    $results = Get-JiraIssue -Query $jql

                    $results | Should -Not -BeNullOrEmpty
                    @($results)[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Issue'
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
                    if ([string]::IsNullOrEmpty($fixtures.TestProject) -or [string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT or JIRA_TEST_ISSUE not configured"
                        return
                    }
                    # Keep the AND predicate anchored to a known fixture issue to avoid
                    # intermittent Jira 11 backend null-deref failures on some status
                    # comparisons against freshly provisioned datasets.
                    $jql = "project = $($fixtures.TestProject) AND key = $($fixtures.TestIssue)"

                    $results = Get-JiraIssue -Query $jql -ErrorAction Stop
                    $results | Should -Not -BeNullOrEmpty
                    @($results).Key | Should -Contain $fixtures.TestIssue
                }

                It "supports OR operator" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject) -or [string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT or JIRA_TEST_ISSUE not configured"
                        return
                    }
                    # Keep this OR query anchored to issue-key predicates only.
                    # Jira 11 can intermittently throw an internal server error on
                    # mixed key/date OR clauses (`key = X OR created >= -Nd`) against
                    # a fresh DC dataset, which makes the test flaky while not proving
                    # anything about JiraPS itself.
                    $jql = "project = $($fixtures.TestProject) AND (key = $($fixtures.TestIssue) OR key = NONEXISTENT-999999)"

                    $results = Get-JiraIssue -Query $jql -ErrorAction Stop

                    $results | Should -Not -BeNullOrEmpty -Because "test project always carries JIRA_TEST_ISSUE"
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
