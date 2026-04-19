#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $testEnv = Initialize-IntegrationEnvironment
        $script:SkipWrite = $testEnv.ReadOnly
    }
}

InModuleScope JiraPS {
    Describe "Attachments" -Tag 'Integration' -Skip:$Skip {
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

        Describe "Get-JiraIssueAttachment" {
            Context "Attachment Retrieval" {
                It "retrieves attachments from an issue" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $attachments = Get-JiraIssueAttachment -Issue $fixtures.TestIssue

                    $attachments | Should -BeOfType [PSCustomObject]
                }

                It "returns attachment objects with correct type" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $attachments = Get-JiraIssueAttachment -Issue $fixtures.TestIssue

                    if ($attachments) {
                        @($attachments)[0].PSObject.TypeNames[0] | Should -Be 'JiraPS.Attachment'
                    }
                }

                It "accepts issue object via pipeline" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $issue = Get-JiraIssue -Key $fixtures.TestIssue

                    { $issue | Get-JiraIssueAttachment } | Should -Not -Throw
                }
            }
        }

        Describe "Add-JiraIssueAttachment" -Skip:$SkipWrite {
            BeforeAll {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    $script:tempIssue = $null
                    $script:testFilePath = $null
                }
                else {
                    $summary = New-TestResourceName -Type "AttachIssue"
                    $script:tempIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary

                    $tempDir = [System.IO.Path]::GetTempPath()
                    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
                    $script:testFilePath = Join-Path $tempDir "jiraps-test-$timestamp.txt"
                    "Test file content created at $(Get-Date)" | Set-Content -Path $testFilePath
                }
            }

            AfterAll {
                if ($testFilePath -and (Test-Path $testFilePath)) {
                    Remove-Item $testFilePath -Force
                }
            }

            Context "Attachment Upload" {
                It "uploads a file to an issue" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $attachment = Add-JiraIssueAttachment -Issue $tempIssue.Key -FilePath $testFilePath -PassThru

                    $attachment | Should -Not -BeNullOrEmpty
                }

                It "returns attachment object with correct type" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $attachment = Add-JiraIssueAttachment -Issue $tempIssue.Key -FilePath $testFilePath -PassThru

                    $attachment.PSObject.TypeNames[0] | Should -Be 'JiraPS.Attachment'
                }

                It "the attachment appears when fetching issue attachments" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    Add-JiraIssueAttachment -Issue $tempIssue.Key -FilePath $testFilePath

                    $attachments = Get-JiraIssueAttachment -Issue $tempIssue.Key

                    $attachments | Should -Not -BeNullOrEmpty
                }
            }

            Context "Error Handling" {
                It "fails for non-existent file" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    { Add-JiraIssueAttachment -Issue $tempIssue.Key -FilePath "C:\nonexistent\file.txt" -ErrorAction Stop } |
                        Should -Throw
                }

                It "fails for non-existent issue" {
                    if (-not $testFilePath) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    { Add-JiraIssueAttachment -Issue 'NONEXISTENT-99999' -FilePath $testFilePath -ErrorAction Stop } |
                        Should -Throw
                }
            }
        }

        Describe "Remove-JiraIssueAttachment" -Skip:$SkipWrite {
            BeforeAll {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    $script:deleteTestIssue = $null
                    $script:deleteTestFile = $null
                }
                else {
                    $summary = New-TestResourceName -Type "AttachDelete"
                    $script:deleteTestIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary

                    $tempDir = [System.IO.Path]::GetTempPath()
                    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
                    $script:deleteTestFile = Join-Path $tempDir "jiraps-delete-test-$timestamp.txt"
                    "Delete test content" | Set-Content -Path $deleteTestFile
                }
            }

            AfterAll {
                if ($deleteTestIssue -and $deleteTestIssue.Key) {
                    Remove-JiraIssue -IssueId $deleteTestIssue.Key -Force -ErrorAction SilentlyContinue
                }
                if ($deleteTestFile -and (Test-Path $deleteTestFile)) {
                    Remove-Item $deleteTestFile -Force
                }
            }

            Context "Attachment Deletion" {
                It "deletes an attachment" {
                    if (-not $deleteTestIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $attachment = Add-JiraIssueAttachment -Issue $deleteTestIssue.Key -FilePath $deleteTestFile -PassThru
                    if (-not $attachment -or -not $attachment.Id) {
                        Set-ItResult -Skipped -Because "Add-JiraIssueAttachment returned null (module bug)"
                        return
                    }

                    { Remove-JiraIssueAttachment -AttachmentId $attachment.Id -Force } | Should -Not -Throw

                    $remaining = Get-JiraIssueAttachment -Issue $deleteTestIssue.Key
                    $matchingAttachment = $remaining | Where-Object { $_.Id -eq $attachment.Id }
                    $matchingAttachment | Should -BeNullOrEmpty
                }
            }
        }
    }
}
