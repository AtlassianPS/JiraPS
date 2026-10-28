#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

<#
.SYNOPSIS
    Integration tests for Issue Watcher cmdlets.

.DESCRIPTION
    Tests issue watcher functionality against a live Jira Cloud or Data Center instance.
    Covers:
    - Get-JiraIssueWatcher
    - Add-JiraIssueWatcher
    - Remove-JiraIssueWatcher

.NOTES
    Watchers are users who receive notifications about changes to an issue.
    On Jira Cloud, watchers are identified by accountId.
    On Jira Data Center, watchers are identified by username.

    These tests require JIRA_TEST_USER to identify a valid user by accountId
    on Cloud or username on Data Center.
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
    Describe "Issue Watchers" -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
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
                        Remove-JiraIssue -Issue $key -Confirm:$false -ErrorAction SilentlyContinue
                    }
                    catch {
                        Write-Verbose "Cleanup: Failed to remove issue $key - $_"
                    }
                }
            }
            Disconnect-Jira -ErrorAction SilentlyContinue
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

                It "accepts issue object via pipeline" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }

                    $issue = Get-JiraIssue -Key $fixtures.TestIssue
                    { $issue | Get-JiraIssueWatcher } | Should -Not -Throw
                }
            }

        }

        Context "Watcher Write Operations" -Skip:$SkipWrite {
            It "adds and removes a watcher using deployment-specific identity" {
                foreach ($required in 'TestProject', 'TestUser') {
                    if ([string]::IsNullOrWhiteSpace($fixtures[$required])) { throw "Watcher integration tests require fixture '$required'." }
                }
                $issue = New-TemporaryTestIssue -Fixtures $fixtures -Summary (New-TestResourceName -Type "WatcherRoundTrip")
                $null = $script:createdIssues.Add($issue.Key)
                $existing = @(Get-JiraIssueWatcher -Issue $issue -ErrorAction Stop)
                if ($existing | Where-Object { $_.($fixtures.UserIdProperty) -eq $fixtures.TestUser }) {
                    Remove-JiraIssueWatcher -Issue $issue -Watcher $fixtures.TestUser -ErrorAction Stop
                }
                $before = @(Get-JiraIssueWatcher -Issue $issue -ErrorAction Stop)
                @($before | Where-Object { $_.($fixtures.UserIdProperty) -eq $fixtures.TestUser }).Count | Should -Be 0

                Add-JiraIssueWatcher -Issue $issue.Key -Watcher $fixtures.TestUser -ErrorAction Stop

                $watchers = @(Get-JiraIssueWatcher -Issue $issue.Key -ErrorAction Stop)
                $matching = @($watchers | Where-Object { $_.($fixtures.UserIdProperty) -eq $fixtures.TestUser })
                $matching.Count | Should -Be 1
                $matching[0] | Should -BeOfType ([AtlassianPS.JiraPS.User])
                $matching[0].DisplayName | Should -Not -BeNullOrEmpty

                Remove-JiraIssueWatcher -Issue $issue.Key -Watcher $fixtures.TestUser -ErrorAction Stop

                $remaining = @(Get-JiraIssueWatcher -Issue $issue.Key -ErrorAction Stop)
                @($remaining | Where-Object { $_.($fixtures.UserIdProperty) -eq $fixtures.TestUser }).Count | Should -Be 0
            }

            It "accepts issue objects via pipeline when adding and removing watchers" {
                foreach ($required in 'TestProject', 'TestUser') {
                    if ([string]::IsNullOrWhiteSpace($fixtures[$required])) { throw "Watcher integration tests require fixture '$required'." }
                }
                $issue = New-TemporaryTestIssue -Fixtures $fixtures -Summary (New-TestResourceName -Type "WatcherPipeline")
                $null = $script:createdIssues.Add($issue.Key)
                $existing = @(Get-JiraIssueWatcher -Issue $issue -ErrorAction Stop)
                if ($existing | Where-Object { $_.($fixtures.UserIdProperty) -eq $fixtures.TestUser }) {
                    Remove-JiraIssueWatcher -Issue $issue -Watcher $fixtures.TestUser -ErrorAction Stop
                }
                $before = @(Get-JiraIssueWatcher -Issue $issue -ErrorAction Stop)
                @($before | Where-Object { $_.($fixtures.UserIdProperty) -eq $fixtures.TestUser }).Count | Should -Be 0

                $issue | Add-JiraIssueWatcher -Watcher $fixtures.TestUser -ErrorAction Stop
                $watchers = @($issue | Get-JiraIssueWatcher -ErrorAction Stop)
                @($watchers | Where-Object { $_.($fixtures.UserIdProperty) -eq $fixtures.TestUser }).Count | Should -Be 1

                $issue | Remove-JiraIssueWatcher -Watcher $fixtures.TestUser -ErrorAction Stop
                $remaining = @($issue | Get-JiraIssueWatcher -ErrorAction Stop)
                @($remaining | Where-Object { $_.($fixtures.UserIdProperty) -eq $fixtures.TestUser }).Count | Should -Be 0
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
