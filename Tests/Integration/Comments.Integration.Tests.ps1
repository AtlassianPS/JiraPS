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
    Describe "Issue Comments" -Tag 'Integration' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
        }

        AfterAll {
            if ($tempIssue -and $tempIssue.Key) {
                Remove-JiraIssue -IssueId $tempIssue.Key -Force -ErrorAction SilentlyContinue
            }
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Describe "Get-JiraIssueComment" {
            Context "Reading Comments" {
                It "retrieves comments from an issue" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $comments = Get-JiraIssueComment -Issue $fixtures.TestIssue

                    $comments | Should -BeOfType [PSCustomObject]
                }

                It "returns comment objects with correct type" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $comments = Get-JiraIssueComment -Issue $fixtures.TestIssue

                    if ($comments) {
                        $comments[0].PSObject.TypeNames[0] | Should -Be 'JiraPS.Comment'
                    }
                }

                It "accepts issue key as string" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    { Get-JiraIssueComment -Issue $fixtures.TestIssue } | Should -Not -Throw
                }

                It "accepts issue object via pipeline" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $issue = Get-JiraIssue -Key $fixtures.TestIssue

                    { $issue | Get-JiraIssueComment } | Should -Not -Throw
                }
            }

            Context "Comment Properties" {
                BeforeAll {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        $script:comments = $null
                    }
                    else {
                        $script:comments = Get-JiraIssueComment -Issue $fixtures.TestIssue
                    }
                }

                It "includes comment body as string" {
                    if (-not $comments) {
                        Set-ItResult -Skipped -Because "No comments exist on test issue"
                        return
                    }
                    $comments[0].Body | Should -BeOfType [string]
                }

                It "includes author information" {
                    if (-not $comments) {
                        Set-ItResult -Skipped -Because "No comments exist on test issue"
                        return
                    }
                    $comments[0].Author | Should -Not -BeNullOrEmpty
                }

                It "includes creation date" {
                    if (-not $comments) {
                        Set-ItResult -Skipped -Because "No comments exist on test issue"
                        return
                    }
                    $comments[0].Created | Should -Not -BeNullOrEmpty
                }
            }
        }

        Describe "Add-JiraIssueComment" -Skip:$SkipWrite {
            BeforeAll {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    $script:tempIssue = $null
                }
                else {
                    $summary = New-TestResourceName -Type "CommentIssue"
                    $script:tempIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                }
            }

            Context "Adding Comments" {
                It "adds a comment to an issue" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $commentBody = "Test comment added at $(Get-Date)"

                    $result = Add-JiraIssueComment -Issue $tempIssue.Key -Comment $commentBody

                    $result | Should -Not -BeNullOrEmpty
                    $result.Body | Should -Match "Test comment"
                }

                It "returns a comment object with correct type" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $commentBody = "Type test comment $(Get-Date -Format 'HHmmss')"

                    $result = Add-JiraIssueComment -Issue $tempIssue.Key -Comment $commentBody

                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.Comment'
                }

                It "accepts issue object via pipeline" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $commentBody = "Pipeline comment $(Get-Date -Format 'HHmmss')"

                    $result = $tempIssue | Add-JiraIssueComment -Comment $commentBody

                    $result | Should -Not -BeNullOrEmpty
                }

                It "the comment appears when fetching issue comments" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $uniqueMarker = "UNIQUE_$(Get-Date -Format 'HHmmssff')"
                    Add-JiraIssueComment -Issue $tempIssue.Key -Comment "Verification comment $uniqueMarker"

                    $comments = Get-JiraIssueComment -Issue $tempIssue.Key

                    $matchingComment = $comments | Where-Object { $_.Body -match $uniqueMarker }
                    $matchingComment | Should -Not -BeNullOrEmpty
                }
            }

            Context "Error Handling" {
                It "fails for non-existent issue" {
                    { Add-JiraIssueComment -Issue 'NONEXISTENT-99999' -Comment 'Test' -ErrorAction Stop } |
                        Should -Throw
                }

                It "fails with empty comment" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    { Add-JiraIssueComment -Issue $tempIssue.Key -Comment '' -ErrorAction Stop } |
                        Should -Throw
                }
            }
        }
    }
}
