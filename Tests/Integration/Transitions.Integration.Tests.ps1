#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

<#
.SYNOPSIS
    Integration tests for Invoke-JiraIssueTransition.

.DESCRIPTION
    Tests workflow transitions against a live Jira Cloud instance.
    Transitions are core Jira functionality for moving issues through workflows.

.NOTES
    These tests require:
    - A project with a workflow that has at least one available transition
    - Ability to create issues (JIRA_TEST_READONLY must be false)

    The default Jira Cloud "Task" workflow typically includes:
    - "To Do" -> "In Progress" (transition)
    - "In Progress" -> "Done" (transition)
    - "In Progress" -> "To Do" (transition back)
#>

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
    Describe "Invoke-JiraIssueTransition" -Tag 'Integration' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env

            $script:createdIssues = [System.Collections.ArrayList]::new()

            Remove-StaleTestResource -Fixtures $fixtures
        }

        AfterAll {
            if ($script:createdIssues -and $script:createdIssues.Count -gt 0) {
                foreach ($key in $script:createdIssues) {
                    try {
                        Remove-JiraIssue -IssueId $key -Force -ErrorAction SilentlyContinue
                    }
                    catch {
                        Write-Verbose "Cleanup: Failed to remove issue $key - $_"
                    }
                }
            }
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Context "Read Operations" {
            It "retrieves available transitions for an issue" {
                if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                    return
                }
                $issue = Get-JiraIssue -Key $fixtures.TestIssue

                $issue.Transition | Should -Not -BeNullOrEmpty
                $issue.Transition | Should -BeOfType [PSCustomObject]
            }

            It "transitions have Id and Name properties" {
                if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                    return
                }
                $issue = Get-JiraIssue -Key $fixtures.TestIssue

                if ($issue.Transition) {
                    $issue.Transition[0].Id | Should -Not -BeNullOrEmpty
                    $issue.Transition[0].Name | Should -Not -BeNullOrEmpty
                }
            }
        }

        Context "Transition Operations" -Skip:$SkipWrite {
            BeforeAll {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    $script:transitionIssue = $null
                }
                else {
                    $summary = New-TestResourceName -Type "Transition"
                    $script:transitionIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                    if ($transitionIssue) {
                        $null = $script:createdIssues.Add($transitionIssue.Key)
                    }
                }
            }

            It "transitions an issue using transition ID" {
                if (-not $transitionIssue) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }

                $issue = Get-JiraIssue -Key $transitionIssue.Key
                $availableTransitions = $issue.Transition

                if (-not $availableTransitions -or $availableTransitions.Count -eq 0) {
                    Set-ItResult -Skipped -Because "No transitions available for issue"
                    return
                }

                $targetTransition = $availableTransitions[0]

                { Invoke-JiraIssueTransition -Issue $issue.Key -Transition $targetTransition.Id } |
                    Should -Not -Throw
            }

            It "transitions an issue using transition object" {
                if (-not $transitionIssue) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }

                $issue = Get-JiraIssue -Key $transitionIssue.Key
                $availableTransitions = $issue.Transition

                if (-not $availableTransitions -or $availableTransitions.Count -eq 0) {
                    Set-ItResult -Skipped -Because "No transitions available for issue"
                    return
                }

                $targetTransition = $availableTransitions[0]

                { Invoke-JiraIssueTransition -Issue $issue.Key -Transition $targetTransition } |
                    Should -Not -Throw
            }

            It "returns the updated issue with -Passthru" {
                if (-not $transitionIssue) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }

                $issue = Get-JiraIssue -Key $transitionIssue.Key
                $availableTransitions = $issue.Transition

                if (-not $availableTransitions -or $availableTransitions.Count -eq 0) {
                    Set-ItResult -Skipped -Because "No transitions available for issue"
                    return
                }

                $targetTransition = $availableTransitions[0]

                $result = Invoke-JiraIssueTransition -Issue $issue.Key -Transition $targetTransition.Id -Passthru

                $result | Should -Not -BeNullOrEmpty
                $result.Key | Should -Be $issue.Key
            }

            It "accepts issue object via pipeline" {
                if (-not $transitionIssue) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }

                $issue = Get-JiraIssue -Key $transitionIssue.Key
                $availableTransitions = $issue.Transition

                if (-not $availableTransitions -or $availableTransitions.Count -eq 0) {
                    Set-ItResult -Skipped -Because "No transitions available for issue"
                    return
                }

                $targetTransition = $availableTransitions[0]

                { $issue | Invoke-JiraIssueTransition -Transition $targetTransition.Id } |
                    Should -Not -Throw
            }

            It "transitions with a comment" {
                if (-not $transitionIssue) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }

                $issue = Get-JiraIssue -Key $transitionIssue.Key
                $availableTransitions = $issue.Transition

                if (-not $availableTransitions -or $availableTransitions.Count -eq 0) {
                    Set-ItResult -Skipped -Because "No transitions available for issue"
                    return
                }

                $targetTransition = $availableTransitions[0]
                $commentText = "Transition comment added at $(Get-Date)"

                { Invoke-JiraIssueTransition -Issue $issue.Key -Transition $targetTransition.Id -Comment $commentText } |
                    Should -Not -Throw

                $comments = Get-JiraIssueComment -Issue $issue.Key
                $latestComment = $comments | Select-Object -Last 1
                $latestComment.Body | Should -Match "Transition comment"
            }
        }

        Context "Transition Cycle" -Skip:$SkipWrite {
            It "completes a full transition cycle (To Do -> In Progress -> To Do)" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }

                $summary = New-TestResourceName -Type "TransitionCycle"
                $issue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                $null = $script:createdIssues.Add($issue.Key)

                $initialStatus = $issue.Status.Name
                $issue = Get-JiraIssue -Key $issue.Key
                $availableTransitions = $issue.Transition

                if (-not $availableTransitions -or $availableTransitions.Count -eq 0) {
                    Set-ItResult -Skipped -Because "No transitions available for new issue"
                    return
                }

                $firstTransition = $availableTransitions[0]
                Invoke-JiraIssueTransition -Issue $issue.Key -Transition $firstTransition.Id

                $afterFirst = Get-JiraIssue -Key $issue.Key
                $afterFirst.Status.Name | Should -Not -Be $initialStatus

                $backTransitions = $afterFirst.Transition
                if ($backTransitions -and $backTransitions.Count -gt 0) {
                    Invoke-JiraIssueTransition -Issue $issue.Key -Transition $backTransitions[0].Id

                    $afterSecond = Get-JiraIssue -Key $issue.Key
                    $afterSecond.Status.Name | Should -Not -Be $afterFirst.Status.Name
                }
            }
        }

        Context "Error Handling" {
            It "fails for non-existent issue" {
                { Invoke-JiraIssueTransition -Issue 'NONEXISTENT-99999' -Transition 1 -ErrorAction Stop } |
                    Should -Throw
            }

            It "fails for invalid transition ID" {
                if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                    return
                }

                { Invoke-JiraIssueTransition -Issue $fixtures.TestIssue -Transition 99999 -ErrorAction Stop } |
                    Should -Throw
            }
        }
    }
}
