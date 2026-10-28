#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

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
            $script:ownedSearchIssue = $null
            if ([string]::IsNullOrWhiteSpace($fixtures.TestIssue)) { throw 'Search integration requires JIRA_TEST_ISSUE to identify a stable baseline issue.' }
            $script:searchKeys = @($fixtures.TestIssue)
            if (-not $fixtures.ReadOnly) {
                $script:ownedSearchIssue = New-TemporaryTestIssue -Fixtures $fixtures -ErrorAction Stop
                $script:searchKeys += $ownedSearchIssue.Key
            }
            # Other suites create and delete project issues concurrently; keep search membership stable.
            $script:searchJql = 'key in (' + ($searchKeys -join ',') + ')'
            $deadline = (Get-Date).AddSeconds(15)
            do {
                $indexed = @(Get-JiraIssue -Query $searchJql -Fields summary -ErrorAction Stop)
                if ((@($indexed.Key | Sort-Object) -join ',') -eq (@($searchKeys | Sort-Object) -join ',')) { break }
                if ((Get-Date) -ge $deadline) { throw 'Search fixtures did not become visible in the Jira index.' }
                Start-Sleep -Milliseconds 500
            } while ($true)
        }

        AfterAll {
            try {
                if ($ownedSearchIssue) { Remove-JiraIssue -Issue $ownedSearchIssue.Key -Confirm:$false -ErrorAction Stop }
            }
            finally { Disconnect-Jira -ErrorAction SilentlyContinue }
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
                    $jql = if ([string]::IsNullOrEmpty($fixtures.TestIssue)) { "project = $($fixtures.TestProject)" }
                    else { "project = $($fixtures.TestProject) AND key = $($fixtures.TestIssue)" }

                    $results = Get-JiraIssue -Query $jql

                    $results | Should -Not -BeNullOrEmpty
                    if ($fixtures.TestIssue) { @($results).Key | Should -Contain $fixtures.TestIssue }
                }

                It "returns issue objects" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $jql = if ([string]::IsNullOrEmpty($fixtures.TestIssue)) { "project = $($fixtures.TestProject)" }
                    else { "project = $($fixtures.TestProject) AND key = $($fixtures.TestIssue)" }

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
                    $jql = "key = $($searchKeys[0]) OR key = $($searchKeys[-1])"

                    $results = Get-JiraIssue -Query $jql -ErrorAction Stop

                    $results | Should -Not -BeNullOrEmpty -Because "test project always carries JIRA_TEST_ISSUE"
                    @($results).Key | Should -Contain $fixtures.TestIssue
                }

                It "supports ORDER BY" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject) -or [string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT or JIRA_TEST_ISSUE not configured"
                        return
                    }
                    # Fresh Jira DC boots can briefly return an empty project-only search while
                    # indexing catches up, so keep ORDER BY anchored to the known fixture issue.
                    $jql = "project = $($fixtures.TestProject) AND key = $($fixtures.TestIssue) ORDER BY created DESC"

                    $results = Get-JiraIssue -Query $jql -ErrorAction Stop

                    $results | Should -Not -BeNullOrEmpty
                    @($results)[0].Key | Should -Be $fixtures.TestIssue
                }
            }

            Context "Pagination" {
                It "supports -First parameter" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $jql = $searchJql

                    $results = @(Get-JiraIssue -Query $jql -First 1 -ErrorAction Stop)

                    @($results).Count | Should -Be 1
                    $searchKeys | Should -Contain $results[0].Key
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

                    $jql = "$searchJql ORDER BY key ASC"

                    $firstPage = @(Get-JiraIssue -Query $jql -First 1 -Skip 0 -ErrorAction Stop)
                    $secondPage = @(Get-JiraIssue -Query $jql -First 1 -Skip 1 -ErrorAction Stop)

                    $firstPage.Count | Should -Be 1
                    if ($searchKeys.Count -gt 1) {
                        $secondPage.Count | Should -Be 1
                        $firstPage[0].Key | Should -Not -Be $secondPage[0].Key
                        @($firstPage[0].Key, $secondPage[0].Key | Sort-Object) | Should -Be @($searchKeys | Sort-Object)
                    }
                    else { $secondPage.Count | Should -Be 0 }
                }

                It "supports -PageSize for automatic paging" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $jql = $searchJql

                    $results = @(Get-JiraIssue -Query $jql -PageSize 1 -ErrorAction Stop)

                    $results.Count | Should -Be $searchKeys.Count
                    @($results.Key | Sort-Object) | Should -Be @($searchKeys | Sort-Object)
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
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $jql = "key = $($fixtures.TestIssue) AND key != $($fixtures.TestIssue)"

                    $results = Get-JiraIssue -Query $jql -ErrorAction Stop

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
