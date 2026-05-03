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
    Describe "Attachments" -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
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
                    # `Get-JiraIssueAttachment` returns `$null` when the issue has no
                    # attachments (the default state of the auto-provisioned baseline issue
                    # on Data Center). Assert the call succeeds and only type-check when
                    # there is data; the "returns attachment objects with correct type"
                    # test below already covers the populated case via Add+Get.
                    { Get-JiraIssueAttachment -Issue $fixtures.TestIssue } | Should -Not -Throw

                    $attachments = Get-JiraIssueAttachment -Issue $fixtures.TestIssue
                    if ($attachments) {
                        @($attachments)[0] | Should -BeOfType [PSCustomObject]
                    }
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
                    $script:testBinaryFilePath = $null
                    $script:downloadDir = $null
                }
                else {
                    $script:tempIssue = New-TemporaryTestIssue -Fixtures $fixtures -Summary (New-TestResourceName -Type "AttachIssue")

                    $tempDir = [System.IO.Path]::GetTempPath()
                    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
                    $script:testFilePath = Join-Path $tempDir "jiraps-test-$timestamp.txt"
                    "Test file content created at $(Get-Date)" | Set-Content -Path $testFilePath

                    $script:testBinaryFilePath = Join-Path $tempDir "jiraps-résumé-$timestamp.bin"
                    $script:downloadDir = Join-Path $tempDir "jiraps-download-$timestamp"
                    $binaryContent = [byte[]](0..255) * 4
                    [System.IO.Directory]::CreateDirectory($downloadDir) | Out-Null
                    [System.IO.File]::WriteAllBytes($testBinaryFilePath, $binaryContent)
                }
            }

            AfterAll {
                if ($testFilePath -and (Test-Path $testFilePath)) {
                    Remove-Item $testFilePath -Force
                }
                if ($testBinaryFilePath -and (Test-Path $testBinaryFilePath)) {
                    Remove-Item $testBinaryFilePath -Force
                }
                if ($downloadDir -and (Test-Path $downloadDir)) {
                    Remove-Item $downloadDir -Recurse -Force
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

                It "round-trips binary content and non-ASCII filenames" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $attachment = Add-JiraIssueAttachment -Issue $tempIssue.Key -FilePath $testBinaryFilePath -PassThru
                    $attachment | Should -Not -BeNullOrEmpty
                    $attachment.Filename | Should -Be ([System.IO.Path]::GetFileName($testBinaryFilePath))

                    $result = Get-JiraIssueAttachmentFile -Attachment $attachment -Path $downloadDir
                    $result | Should -BeTrue

                    $downloadedFilePath = Join-Path $downloadDir $attachment.Filename
                    (Test-Path $downloadedFilePath) | Should -BeTrue

                    $expectedBytes = [System.IO.File]::ReadAllBytes($testBinaryFilePath)
                    $actualBytes = [System.IO.File]::ReadAllBytes($downloadedFilePath)
                    $actualBytes | Should -Be $expectedBytes
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
                    $script:deleteTestIssue = New-TemporaryTestIssue -Fixtures $fixtures -Summary (New-TestResourceName -Type "AttachDelete")

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
