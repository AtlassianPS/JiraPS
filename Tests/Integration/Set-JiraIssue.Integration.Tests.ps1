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
    Describe "Set-JiraIssue" -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
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

        Context "Update Operations" -Skip:$SkipWrite {
            BeforeAll {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    $script:tempIssue = $null
                }
                else {
                    $script:tempIssue = New-TemporaryTestIssue -Fixtures $fixtures -Summary (New-TestResourceName -Type "SetIssue")
                }
            }

            It "updates the summary" {
                if (-not $tempIssue) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $newSummary = New-TestResourceName -Type "SetIssueUpdated"

                Set-JiraIssue -Issue $tempIssue.Key -Summary $newSummary

                $updated = Get-JiraIssue -Key $tempIssue.Key
                $updated.Summary | Should -Be $newSummary
            }

            It "updates the description" {
                if (-not $tempIssue) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $newDescription = "Updated description at $(Get-Date)"

                Set-JiraIssue -Issue $tempIssue.Key -Description $newDescription

                $updated = Get-JiraIssue -Key $tempIssue.Key
                $updated.Description | Should -Match "Updated description"
            }

            It "accepts issue object via pipeline" {
                if (-not $tempIssue) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $issue = Get-JiraIssue -Key $tempIssue.Key
                $newSummary = "Pipeline Updated $(Get-Date -Format 'HHmmss')"

                $issue | Set-JiraIssue -Summary $newSummary

                $updated = Get-JiraIssue -Key $tempIssue.Key
                $updated.Summary | Should -Be $newSummary
            }

            It "updates using -Fields parameter" {
                if (-not $tempIssue) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $fields = @{
                    summary = "Fields Parameter Update $(Get-Date -Format 'HHmmss')"
                }

                Set-JiraIssue -Issue $tempIssue.Key -Fields $fields

                $updated = Get-JiraIssue -Key $tempIssue.Key
                $updated.Summary | Should -Match "Fields Parameter Update"
            }

            It "returns the updated issue with -PassThru" {
                if (-not $tempIssue) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $newSummary = "PassThru Test $(Get-Date -Format 'HHmmss')"

                $result = Set-JiraIssue -Issue $tempIssue.Key -Summary $newSummary -PassThru

                $result | Should -Not -BeNullOrEmpty
                $result.Summary | Should -Be $newSummary
            }
        }

        Context "Error Handling" -Skip:$SkipWrite {
            It "fails for non-existent issue" {
                { Set-JiraIssue -Issue 'NONEXISTENT-99999' -Summary 'Test' -ErrorAction Stop } |
                    Should -Throw
            }
        }
    }
}
