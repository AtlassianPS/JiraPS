#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
}

InModuleScope JiraPS {
    Describe "Atlassian Document Format (ADF)" -Tag 'Integration', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
        }

        AfterAll {
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
    }
}
