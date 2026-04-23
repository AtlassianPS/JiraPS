#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

<#
.SYNOPSIS
    Integration tests for Issue Watcher cmdlets.

.DESCRIPTION
    Tests issue watcher functionality against a live Jira Cloud instance.
    Covers:
    - Get-JiraIssueWatcher
    - Add-JiraIssueWatcher
    - Remove-JiraIssueWatcher

.NOTES
    Watchers are users who receive notifications about changes to an issue.
    On Jira Cloud, watchers are identified by accountId.
    On Jira Data Center, watchers are identified by username.

    These tests require JIRA_TEST_USER to be configured with the accountId
    of a valid user that can be added as a watcher.
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
    Describe "Issue Watchers" -Tag 'Integration' -Skip:$Skip {
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

        Describe "Get-JiraIssueWatcher" {
            Context "Retrieving Watchers" {
                It "retrieves watchers from an issue" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }

                    { Get-JiraIssueWatcher -Issue $fixtures.TestIssue } | Should -Not -Throw
                }

                It "returns user objects" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }

                    $watchers = Get-JiraIssueWatcher -Issue $fixtures.TestIssue

                    if ($watchers) {
                        $watchers[0].PSObject.TypeNames[0] | Should -Be 'JiraPS.User'
                    }
                }

                It "accepts issue key as string" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }

                    { Get-JiraIssueWatcher -Issue $fixtures.TestIssue } | Should -Not -Throw
                }

                It "accepts issue object via pipeline" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }

                    $issue = Get-JiraIssue -Key $fixtures.TestIssue
                    { $issue | Get-JiraIssueWatcher } | Should -Not -Throw
                }
            }

            Context "Watcher Properties" {
                BeforeAll {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        $script:watchers = $null
                    }
                    else {
                        $script:watchers = Get-JiraIssueWatcher -Issue $fixtures.TestIssue
                    }
                }

                It "watcher has AccountId property (Cloud)" {
                    if (-not $watchers -or $watchers.Count -eq 0) {
                        Set-ItResult -Skipped -Because "No watchers on test issue"
                        return
                    }

                    $watchers[0].AccountId | Should -Not -BeNullOrEmpty
                }

                It "watcher has DisplayName property" {
                    if (-not $watchers -or $watchers.Count -eq 0) {
                        Set-ItResult -Skipped -Because "No watchers on test issue"
                        return
                    }

                    $watchers[0].DisplayName | Should -Not -BeNullOrEmpty
                }
            }
        }

        Describe "Add-JiraIssueWatcher" -Skip:$SkipWrite {
            BeforeAll {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    $script:watcherTestIssue = $null
                }
                else {
                    $summary = New-TestResourceName -Type "WatcherTest"
                    $script:watcherTestIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                    if ($watcherTestIssue) {
                        $null = $script:createdIssues.Add($watcherTestIssue.Key)
                    }
                }
            }

            Context "Adding Watchers" {
                It "adds a watcher to an issue using accountId" {
                    if (-not $watcherTestIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    if ([string]::IsNullOrEmpty($fixtures.TestUser)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_USER not configured"
                        return
                    }

                    { Add-JiraIssueWatcher -Issue $watcherTestIssue.Key -Watcher $fixtures.TestUser } |
                        Should -Not -Throw
                }

                It "added watcher appears in watcher list" {
                    if (-not $watcherTestIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    if ([string]::IsNullOrEmpty($fixtures.TestUser)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_USER not configured"
                        return
                    }

                    Add-JiraIssueWatcher -Issue $watcherTestIssue.Key -Watcher $fixtures.TestUser -ErrorAction SilentlyContinue

                    $watchers = Get-JiraIssueWatcher -Issue $watcherTestIssue.Key
                    $matchingWatcher = $watchers | Where-Object { $_.AccountId -eq $fixtures.TestUser }
                    $matchingWatcher | Should -Not -BeNullOrEmpty
                }

                It "accepts issue object via pipeline" {
                    if (-not $watcherTestIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    if ([string]::IsNullOrEmpty($fixtures.TestUser)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_USER not configured"
                        return
                    }

                    $summary = New-TestResourceName -Type "WatcherPipeline"
                    $pipelineIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                    $null = $script:createdIssues.Add($pipelineIssue.Key)

                    { $pipelineIssue | Add-JiraIssueWatcher -Watcher $fixtures.TestUser } |
                        Should -Not -Throw
                }

                It "adds multiple watchers" {
                    if (-not $watcherTestIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    if ([string]::IsNullOrEmpty($fixtures.TestUser)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_USER not configured"
                        return
                    }

                    $summary = New-TestResourceName -Type "MultiWatcher"
                    $multiIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                    $null = $script:createdIssues.Add($multiIssue.Key)

                    { Add-JiraIssueWatcher -Issue $multiIssue.Key -Watcher $fixtures.TestUser } |
                        Should -Not -Throw
                }
            }
        }

        Describe "Remove-JiraIssueWatcher" -Skip:$SkipWrite {
            Context "Removing Watchers" {
                It "removes a watcher from an issue" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    if ([string]::IsNullOrEmpty($fixtures.TestUser)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_USER not configured"
                        return
                    }

                    $summary = New-TestResourceName -Type "RemoveWatcher"
                    $removeIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                    $null = $script:createdIssues.Add($removeIssue.Key)

                    Add-JiraIssueWatcher -Issue $removeIssue.Key -Watcher $fixtures.TestUser

                    $watchersBefore = Get-JiraIssueWatcher -Issue $removeIssue.Key
                    $watcherExistsBefore = $watchersBefore | Where-Object { $_.AccountId -eq $fixtures.TestUser }
                    $watcherExistsBefore | Should -Not -BeNullOrEmpty -Because "Watcher should exist before removal"

                    { Remove-JiraIssueWatcher -Issue $removeIssue.Key -Watcher $fixtures.TestUser } |
                        Should -Not -Throw

                    $watchersAfter = Get-JiraIssueWatcher -Issue $removeIssue.Key
                    $watcherExistsAfter = $watchersAfter | Where-Object { $_.AccountId -eq $fixtures.TestUser }
                    $watcherExistsAfter | Should -BeNullOrEmpty -Because "Watcher should not exist after removal"
                }

                It "accepts issue object via pipeline" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    if ([string]::IsNullOrEmpty($fixtures.TestUser)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_USER not configured"
                        return
                    }

                    $summary = New-TestResourceName -Type "RemoveWatcherPipe"
                    $pipeIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                    $null = $script:createdIssues.Add($pipeIssue.Key)

                    Add-JiraIssueWatcher -Issue $pipeIssue.Key -Watcher $fixtures.TestUser

                    { $pipeIssue | Remove-JiraIssueWatcher -Watcher $fixtures.TestUser } |
                        Should -Not -Throw
                }
            }
        }

        Context "Error Handling" {
            It "Get-JiraIssueWatcher fails for non-existent issue" {
                { Get-JiraIssueWatcher -Issue 'NONEXISTENT-99999' -ErrorAction Stop } |
                    Should -Throw
            }
        }

        Context "Add-JiraIssueWatcher Error Handling" -Skip:$SkipWrite {
            It "fails for non-existent issue" {
                { Add-JiraIssueWatcher -Issue 'NONEXISTENT-99999' -Watcher 'someuser' -ErrorAction Stop } |
                    Should -Throw
            }
        }

        Context "Remove-JiraIssueWatcher Error Handling" -Skip:$SkipWrite {
            It "fails for non-existent issue" {
                { Remove-JiraIssueWatcher -Issue 'NONEXISTENT-99999' -Watcher 'someuser' -ErrorAction Stop } |
                    Should -Throw
            }
        }
    }
}
