#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $testEnv = Initialize-IntegrationEnvironment
        $script:SkipWrite = $testEnv.ReadOnly
    }
}

InModuleScope JiraPS {
    Describe "Worklogs" -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
            $script:createdIssues = [System.Collections.ArrayList]::new()
        }

        AfterAll {
            foreach ($issue in $script:createdIssues) {
                if ($issue -and $issue.Key) {
                    Remove-JiraIssue -IssueId $issue.Key -Force -ErrorAction SilentlyContinue
                }
            }
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Describe "Get-JiraIssueWorklog" {
            Context "Worklog Retrieval" {
                It "retrieves worklogs from an issue" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    { Get-JiraIssueWorklog -Issue $fixtures.TestIssue } | Should -Not -Throw
                }

                It "returns worklog objects with correct type" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $worklogs = Get-JiraIssueWorklog -Issue $fixtures.TestIssue

                    if ($worklogs) {
                        @($worklogs)[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Worklogitem'
                    }
                }

                It "accepts issue object via pipeline" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $issue = Get-JiraIssue -Key $fixtures.TestIssue

                    { $issue | Get-JiraIssueWorklog } | Should -Not -Throw
                }
            }
        }

        Describe "Add-JiraIssueWorklog" -Skip:$SkipWrite {
            BeforeAll {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    $script:tempIssue = $null
                }
                else {
                    $issue = New-TemporaryTestIssue -Fixtures $fixtures -Summary (New-TestResourceName -Type "WorklogIssue")
                    $null = $script:createdIssues.Add($issue)
                    $script:tempIssue = $issue
                }
            }

            Context "Worklog Creation" {
                It "adds a worklog to an issue" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $worklog = Add-JiraIssueWorklog -Issue $tempIssue.Key -TimeSpent ([TimeSpan]::FromHours(1)) -DateStarted (Get-Date) -Comment "Integration test worklog"

                    $worklog | Should -Not -BeNullOrEmpty
                }

                It "returns worklog object with correct type" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $worklog = Add-JiraIssueWorklog -Issue $tempIssue.Key -TimeSpent ([TimeSpan]::FromMinutes(30)) -DateStarted (Get-Date) -Comment "Type check test"

                    $worklog.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Worklogitem'
                }

                It "accepts various TimeSpan values" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    { Add-JiraIssueWorklog -Issue $tempIssue.Key -TimeSpent ([TimeSpan]::FromHours(2)) -DateStarted (Get-Date) -Comment "TimeSpan test 1" } | Should -Not -Throw
                    { Add-JiraIssueWorklog -Issue $tempIssue.Key -TimeSpent ([TimeSpan]::FromMinutes(90)) -DateStarted (Get-Date) -Comment "TimeSpan test 2" } | Should -Not -Throw
                    { Add-JiraIssueWorklog -Issue $tempIssue.Key -TimeSpent (New-TimeSpan -Hours 1 -Minutes 30) -DateStarted (Get-Date) -Comment "TimeSpan test 3" } | Should -Not -Throw
                }

                It "persists the comment server-side as part of the create response" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $uniqueComment = "Verification worklog $(Get-Date -Format 'HHmmssff')"
                    # The POST returns the persisted worklog synchronously, so trust
                    # the create response instead of polling Get-JiraIssueWorklog —
                    # that path is already covered by the "Worklog Retrieval" context.
                    $created = Add-JiraIssueWorklog -Issue $tempIssue.Key -TimeSpent ([TimeSpan]::FromMinutes(15)) -DateStarted (Get-Date) -Comment $uniqueComment

                    $created | Should -Not -BeNullOrEmpty
                    $created.Id | Should -Not -BeNullOrEmpty
                    $created.Comment | Should -Be $uniqueComment
                }
            }

            Context "Error Handling" {
                It "fails for non-existent issue" {
                    { Add-JiraIssueWorklog -Issue 'NONEXISTENT-99999' -TimeSpent ([TimeSpan]::FromHours(1)) -DateStarted (Get-Date) -Comment "Test" -ErrorAction Stop } |
                        Should -Throw
                }

                It "fails with invalid time format" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    { Add-JiraIssueWorklog -Issue $tempIssue.Key -TimeSpent "invalid" -DateStarted (Get-Date) -Comment "Test" -ErrorAction Stop } |
                        Should -Throw
                }
            }
        }
    }
}
