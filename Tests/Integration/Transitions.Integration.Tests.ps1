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

    The tests do *not* hardcode transition or status names. Each `It` block
    discovers the available transitions on its target issue at runtime
    (via `Get-JiraIssue -Key $key | Select -ExpandProperty Transition`) and
    selects a transition based on the destination state exposed via the
    `ResultStatus.Name` property of the `JiraPS.Transition` object. This
    keeps the suite green across the various workflows that ship with
    different Jira flavours: the Cloud Software default ("To Do" -> "In
    Progress" -> "Done"), the AMPS standalone bundle's jira-core template
    ("Open" -> "In Progress" -> "Resolved"), and any custom workflow the
    auto-provisioned fixture project might land on.
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
    Describe "Invoke-JiraIssueTransition" -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
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
                    $script:transitionIssue = New-TemporaryTestIssue -Fixtures $fixtures -Summary (New-TestResourceName -Type "Transition")
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
                # Tag the comment with a unique marker so we can find it deterministically.
                # `Get-JiraIssueComment` returns *all* comments on the issue and the prior
                # transition tests in this Context share `$transitionIssue` and may have
                # already added their own audit-log entries; relying on `Select -Last 1`
                # is racy because Jira Server orders comments by `created` and identical
                # timestamps can swap places between the API write and the read-back. The
                # marker also rules out the possibility of a stale cached comment matching
                # the previous incarnation of this test.
                $marker = "TransitionMarker-{0}" -f ([guid]::NewGuid())
                $commentText = "Transition comment $marker added at $(Get-Date)"

                { Invoke-JiraIssueTransition -Issue $issue.Key -Transition $targetTransition.Id -Comment $commentText -ErrorAction Stop } |
                    Should -Not -Throw

                $comments = Get-JiraIssueComment -Issue $issue.Key
                $matchingComment = @($comments) | Where-Object {
                    $_.Body -and ($_.Body -match [regex]::Escape($marker))
                }
                $matchingComment | Should -Not -BeNullOrEmpty -Because "the transition payload included an update.comment.add block carrying our marker [$marker]"
            }
        }

        Context "Transition Cycle" -Skip:$SkipWrite {
            It "completes a transition cycle by picking transitions that change state" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }

                $issue = New-TemporaryTestIssue -Fixtures $fixtures -Summary (New-TestResourceName -Type "TransitionCycle")
                $null = $script:createdIssues.Add($issue.Key)

                $issue = Get-JiraIssue -Key $issue.Key
                $initialStatus = $issue.Status.Name
                $availableTransitions = $issue.Transition

                if (-not $availableTransitions) {
                    Set-ItResult -Skipped -Because "No transitions available for new issue"
                    return
                }

                # `JiraPS.Transition` exposes the destination state via `ResultStatus.Name`
                # (populated by `ConvertTo-JiraTransition` from the `to` block of
                # `/rest/api/2/issue/{id}/transitions`). A naive `[0]` pick races with the
                # workflow definition: on the moveworkforward AMPS image the jira-core
                # template's first available transition can be a self-loop or a guarded
                # conditional that resolves to the current state on a freshly-created
                # issue, which would silently no-op the assertion below. Filter to
                # transitions whose destination differs from the current state so this
                # test is workflow-agnostic.
                $forwardTransitions = @($availableTransitions | Where-Object {
                        $_.ResultStatus -and $_.ResultStatus.Name -and $_.ResultStatus.Name -ne $initialStatus
                    })

                if (-not $forwardTransitions) {
                    Set-ItResult -Skipped -Because "No state-changing transitions available from initial status [$initialStatus]"
                    return
                }

                $firstTransition = $forwardTransitions[0]
                $expectedAfterFirst = $firstTransition.ResultStatus.Name
                Invoke-JiraIssueTransition -Issue $issue.Key -Transition $firstTransition.Id -ErrorAction Stop

                $afterFirst = Get-JiraIssue -Key $issue.Key
                $afterFirst.Status.Name | Should -Be $expectedAfterFirst -Because "we picked transition [$($firstTransition.Name)] which targets [$expectedAfterFirst]"

                # Try to cycle to *another* state. Prefer a transition that lands back on
                # the original status (true round-trip) but accept any state-changing
                # transition: many simplified workflows are linear (To Do -> In Progress
                # -> Done with no direct backward edge) and the bidirectional capability
                # is what we actually want to exercise on this code path.
                $backCandidates = @($afterFirst.Transition | Where-Object {
                        $_.ResultStatus -and $_.ResultStatus.Name -and $_.ResultStatus.Name -ne $afterFirst.Status.Name
                    })

                if ($backCandidates) {
                    $preferred = $backCandidates | Where-Object { $_.ResultStatus.Name -eq $initialStatus } | Select-Object -First 1
                    $secondTransition = if ($preferred) { $preferred } else { $backCandidates[0] }
                    $expectedAfterSecond = $secondTransition.ResultStatus.Name

                    Invoke-JiraIssueTransition -Issue $issue.Key -Transition $secondTransition.Id -ErrorAction Stop

                    $afterSecond = Get-JiraIssue -Key $issue.Key
                    $afterSecond.Status.Name | Should -Be $expectedAfterSecond -Because "we picked transition [$($secondTransition.Name)] which targets [$expectedAfterSecond]"
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
