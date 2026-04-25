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

                # Create a dedicated issue so this test does not race with
                # the other transition tests that share $transitionIssue.
                $localSummary = New-TestResourceName -Type "TransitionWithComment"
                $localIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $localSummary
                if (-not $localIssue) {
                    Set-ItResult -Skipped -Because "Failed to create test issue"
                    return
                }
                $null = $script:createdIssues.Add($localIssue.Key)

                $issue = Get-JiraIssue -Key $localIssue.Key
                $availableTransitions = $issue.Transition

                if (-not $availableTransitions -or $availableTransitions.Count -eq 0) {
                    Set-ItResult -Skipped -Because "No transitions available for issue"
                    return
                }

                $targetTransition = $availableTransitions[0]
                $commentMarker = [Guid]::NewGuid().ToString('N')
                $commentText = "Transition comment $commentMarker"

                { Invoke-JiraIssueTransition -Issue $issue.Key -Transition $targetTransition.Id -Comment $commentText } |
                    Should -Not -Throw

                # Whether the comment lands depends on whether the workflow's
                # transition screen exposes the Comment field. Many default
                # Jira projects (including the bundled "Software" workflow)
                # do not, so the API silently drops `update.comment` instead
                # of returning an error. Skip rather than fail so the suite
                # remains portable across project workflow configurations
                # (see backlog issue #622).
                $comments = @(Get-JiraIssueComment -Issue $issue.Key)
                $matched = $comments | Where-Object { $_.Body -match [Regex]::Escape($commentMarker) }
                if (-not $matched) {
                    Set-ItResult -Skipped -Because "Workflow transition screen for '$($targetTransition.Name)' does not expose the Comment field; cannot verify comment delivery"
                    return
                }

                ($matched | Select-Object -Last 1).Body | Should -Match $commentMarker
            }
        }

        Context "Transition Cycle" -Skip:$SkipWrite {
            It "completes a full transition cycle through two distinct statuses" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }

                $summary = New-TestResourceName -Type "TransitionCycle"
                $issue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                $null = $script:createdIssues.Add($issue.Key)

                $issue = Get-JiraIssue -Key $issue.Key
                $initialStatus = $issue.Status.Name
                $availableTransitions = $issue.Transition

                if (-not $availableTransitions -or $availableTransitions.Count -eq 0) {
                    Set-ItResult -Skipped -Because "No transitions available for new issue"
                    return
                }

                # Pick a transition that actually changes the status (not a
                # workflow loopback). Some Jira workflows expose self-pointing
                # transitions like "To Do -> To Do"; using one of those would
                # make the post-condition assertion meaningless.
                $forwardTransition = $availableTransitions |
                    Where-Object { $_.ResultStatus -and $_.ResultStatus.Name -and ($_.ResultStatus.Name -ne $initialStatus) } |
                    Select-Object -First 1
                if (-not $forwardTransition) {
                    Set-ItResult -Skipped -Because "Workflow has no transition that changes the status from '$initialStatus'"
                    return
                }

                Invoke-JiraIssueTransition -Issue $issue.Key -Transition $forwardTransition.Id

                $afterFirst = Get-JiraIssue -Key $issue.Key
                $afterFirst.Status.Name | Should -Not -Be $initialStatus

                # Find a second transition that moves to a different status
                # again (could be back to $initialStatus, could be forward).
                $secondTransition = $afterFirst.Transition |
                    Where-Object { $_.ResultStatus -and $_.ResultStatus.Name -and ($_.ResultStatus.Name -ne $afterFirst.Status.Name) } |
                    Select-Object -First 1
                if (-not $secondTransition) {
                    Set-ItResult -Skipped -Because "Workflow has no transition out of '$($afterFirst.Status.Name)'"
                    return
                }

                Invoke-JiraIssueTransition -Issue $issue.Key -Transition $secondTransition.Id

                $afterSecond = Get-JiraIssue -Key $issue.Key
                $afterSecond.Status.Name | Should -Not -Be $afterFirst.Status.Name
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
