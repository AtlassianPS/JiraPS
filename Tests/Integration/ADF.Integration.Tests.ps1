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
    Describe "Atlassian Document Format (ADF)" -Tag 'Integration' -Skip:$Skip {
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

        Describe "ADF in Issue Description" {
            Context "Cloud API v3 Search (ADF to Markdown)" {
                It "returns description as string from JQL search" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $jql = "key = $($fixtures.TestIssue)"

                    $issue = Get-JiraIssue -Query $jql

                    @($issue)[0].Description | Should -BeOfType [string]
                }

                It "converts ADF to readable text" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $jql = "key = $($fixtures.TestIssue)"

                    $issue = Get-JiraIssue -Query $jql

                    if (@($issue)[0].Description) {
                        @($issue)[0].Description | Should -Not -Match '"type":\s*"doc"'
                    }
                }
            }

            Context "Cloud API v2 by Key (Plain Text)" {
                It "returns description as string from key lookup" {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $issue = Get-JiraIssue -Key $fixtures.TestIssue

                    $issue.Description | Should -BeOfType [string]
                }
            }
        }

        Describe "ADF in Comments" {
            Context "Comment Body Conversion" {
                BeforeAll {
                    if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        $script:comments = $null
                    }
                    else {
                        $script:comments = Get-JiraIssueComment -Issue $fixtures.TestIssue
                    }
                }

                It "returns comment body as string" {
                    if (-not $comments) {
                        Set-ItResult -Skipped -Because "No comments exist on test issue"
                        return
                    }
                    @($comments)[0].Body | Should -BeOfType [string]
                }

                It "does not contain raw ADF JSON" {
                    if (-not $comments) {
                        Set-ItResult -Skipped -Because "No comments exist on test issue"
                        return
                    }
                    @($comments)[0].Body | Should -Not -Match '"type":\s*"doc"'
                }
            }
        }

        Describe "ConvertTo-AtlassianDocumentFormat" {
            Context "Markdown to ADF" {
                It "converts simple text to ADF" {
                    $markdown = "Hello, World!"

                    $adf = ConvertTo-AtlassianDocumentFormat -Markdown $markdown
                    $adfJson = $adf | ConvertTo-Json -Depth 10

                    $adf | Should -Not -BeNullOrEmpty
                    $adfJson | Should -Match '"type":\s*"doc"'
                }

                It "converts headers to ADF" {
                    $markdown = "# Heading 1"

                    $adf = ConvertTo-AtlassianDocumentFormat -Markdown $markdown
                    $adfJson = $adf | ConvertTo-Json -Depth 10

                    $adfJson | Should -Match '"type":\s*"heading"'
                }

                It "converts bullet lists to ADF" -Skip -Tag 'KnownBug' {
                    # Known module limitation: ConvertTo-AtlassianDocumentFormat does not
                    # properly convert markdown bullet lists - they are treated as plain paragraphs.
                    # TODO: Track as GitHub issue and link here when fixed.
                    # See: https://github.com/AtlassianPS/JiraPS/issues/XXX
                    $markdown = "- Item 1`n- Item 2"

                    $adf = ConvertTo-AtlassianDocumentFormat -Markdown $markdown
                    $adfJson = $adf | ConvertTo-Json -Depth 10

                    $adfJson | Should -Match '"type":\s*"bulletList"'
                }

                It "converts code blocks to ADF" {
                    $markdown = "``````powershell`nGet-Process`n``````"

                    $adf = ConvertTo-AtlassianDocumentFormat -Markdown $markdown
                    $adfJson = $adf | ConvertTo-Json -Depth 10

                    $adfJson | Should -Match '"type":\s*"codeBlock"'
                }
            }
        }

        Describe "ConvertFrom-AtlassianDocumentFormat" {
            Context "ADF to Markdown" {
                It "converts simple ADF to text" {
                    $adf = @{
                        type    = "doc"
                        version = 1
                        content = @(
                            @{
                                type    = "paragraph"
                                content = @(
                                    @{
                                        type = "text"
                                        text = "Hello, World!"
                                    }
                                )
                            }
                        )
                    } | ConvertTo-Json -Depth 10

                    $markdown = ConvertFrom-AtlassianDocumentFormat -InputObject $adf

                    $markdown | Should -Match "Hello, World!"
                }

                It "handles plain string input gracefully" {
                    $plainText = "This is not ADF"

                    $result = ConvertFrom-AtlassianDocumentFormat -InputObject $plainText

                    $result | Should -Be $plainText
                }

                It "handles null input" {
                    $result = ConvertFrom-AtlassianDocumentFormat -InputObject $null

                    $result | Should -BeNullOrEmpty
                }
            }
        }

        Describe "Markdown -> ADF round-trip on Cloud" -Skip:$SkipWrite {
            BeforeAll {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    $script:tempIssue = $null
                }
                else {
                    $script:tempIssue = New-TemporaryTestIssue -Fixtures $fixtures
                }
            }

            Context "New-JiraIssue -Description (create path)" {
                It "round-trips a Markdown description created by New-JiraIssue" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $marker = "ADFCREATE_$(Get-Date -Format 'HHmmssff')"
                    $description = "# Heading $marker`n`nA paragraph with **bold**, _italic_, and ``inline code``."

                    $summary = New-TestResourceName -Type "ADFCreateIssue"
                    $created = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary -Description $description

                    try {
                        $created | Should -Not -BeNullOrEmpty

                        # Reading back should render ADF -> plain text, not raw JSON
                        $fetched = Get-JiraIssue -Key $created.Key
                        $fetched.Description | Should -BeOfType [string]
                        $fetched.Description | Should -Not -Match '"type":\s*"doc"'
                        $fetched.Description | Should -Match $marker
                        $fetched.Description | Should -Match 'bold'
                        $fetched.Description | Should -Match 'italic'
                    }
                    finally {
                        if ($created -and $created.Key) {
                            Remove-JiraIssue -IssueId $created.Key -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            }

            Context "Set-JiraIssue -Description (edit path)" {
                It "round-trips a Markdown description set via Set-JiraIssue" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $marker = "ADFEDIT_$(Get-Date -Format 'HHmmssff')"
                    $description = "Edited description $marker with **bold** text."

                    Set-JiraIssue -Issue $tempIssue.Key -Description $description

                    $fetched = Get-JiraIssue -Key $tempIssue.Key
                    $fetched.Description | Should -BeOfType [string]
                    $fetched.Description | Should -Not -Match '"type":\s*"doc"'
                    $fetched.Description | Should -Match $marker
                    $fetched.Description | Should -Match 'bold'
                }
            }

            Context "Add-JiraIssueComment + Get-JiraIssueComment" {
                It "round-trips a Markdown comment body" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $marker = "ADFCOMMENT_$(Get-Date -Format 'HHmmssff')"
                    $body = "## Heading $marker`n`nLine with **bold** and _italic_."

                    $added = Add-JiraIssueComment -Issue $tempIssue.Key -Comment $body

                    $added | Should -Not -BeNullOrEmpty
                    $added.Body | Should -BeOfType [string]
                    $added.Body | Should -Not -Match '"type":\s*"doc"'
                    $added.Body | Should -Match $marker
                    $added.Body | Should -Match 'bold'

                    # Verify it survives a round-trip via Get-JiraIssueComment as well
                    $fetched = Get-JiraIssueComment -Issue $tempIssue.Key
                    $matching = $fetched | Where-Object { $_.Body -match $marker }
                    $matching | Should -Not -BeNullOrEmpty
                    $matching.Body | Should -Not -Match '"type":\s*"doc"'
                }
            }

            Context "Set-JiraIssue -AddComment (edit path)" {
                It "round-trips a Markdown comment added via -AddComment" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $marker = "ADFADDCOMMENT_$(Get-Date -Format 'HHmmssff')"
                    $body = "Edit-comment $marker with **bold**."

                    Set-JiraIssue -Issue $tempIssue.Key -AddComment $body

                    $fetched = Get-JiraIssueComment -Issue $tempIssue.Key
                    $matching = $fetched | Where-Object { $_.Body -match $marker }
                    $matching | Should -Not -BeNullOrEmpty
                    $matching.Body | Should -Not -Match '"type":\s*"doc"'
                    $matching.Body | Should -Match 'bold'
                }
            }

            Context "Add-JiraIssueWorklog + Get-JiraIssueWorklog" {
                It "round-trips a Markdown worklog comment" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $marker = "ADFWORKLOG_$(Get-Date -Format 'HHmmssff')"
                    $body = "Worklog $marker with **bold** prose."

                    $added = Add-JiraIssueWorklog -Issue $tempIssue.Key -Comment $body -TimeSpent ([TimeSpan]::FromMinutes(1)) -DateStarted (Get-Date)

                    $added | Should -Not -BeNullOrEmpty
                    $added.Comment | Should -BeOfType [string]
                    $added.Comment | Should -Not -Match '"type":\s*"doc"'
                    $added.Comment | Should -Match $marker
                    $added.Comment | Should -Match 'bold'

                    $fetched = Get-JiraIssueWorklog -Issue $tempIssue.Key
                    $matching = $fetched | Where-Object { $_.Comment -match $marker }
                    $matching | Should -Not -BeNullOrEmpty
                    $matching.Comment | Should -BeOfType [string]
                    $matching.Comment | Should -Not -Match '"type":\s*"doc"'
                }
            }
        }
    }
}
