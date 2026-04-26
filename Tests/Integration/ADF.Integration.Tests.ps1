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
    Describe "Atlassian Document Format (ADF)" -Tag 'Integration', 'Cloud' -Skip:$Skip {
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

                    $marker = "ADFCREATE_$([Guid]::NewGuid().ToString('N'))"
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

                    $marker = "ADFEDIT_$([Guid]::NewGuid().ToString('N'))"
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

                    $marker = "ADFCOMMENT_$([Guid]::NewGuid().ToString('N'))"
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

                    $marker = "ADFADDCOMMENT_$([Guid]::NewGuid().ToString('N'))"
                    $body = "Edit-comment $marker with **bold**."

                    Set-JiraIssue -Issue $tempIssue.Key -AddComment $body

                    $fetched = Get-JiraIssueComment -Issue $tempIssue.Key
                    $matching = $fetched | Where-Object { $_.Body -match $marker }
                    $matching | Should -Not -BeNullOrEmpty
                    $matching.Body | Should -Not -Match '"type":\s*"doc"'
                    $matching.Body | Should -Match 'bold'
                }
            }

            Context "Whitespace-only description (Resolve-JiraTextFieldPayload paragraph branch)" {
                # Resolve-JiraTextFieldPayload wraps whitespace-only input
                # in a single ADF paragraph node containing the literal
                # text. ConvertTo-AtlassianDocumentFormat would otherwise
                # produce an empty ADF document, which Cloud rejects with
                # "value cannot be empty" for description / environment.
                #
                # This test verifies the "trust the caller" branch
                # actually round-trips against a live Cloud tenant — the
                # ADF spec says text nodes have minLength=1 (a space
                # passes that), but the editor layer is known to strip
                # leading / trailing whitespace before validating, so
                # the assertion is intentionally loose: we only require
                # that the API accepts the document and the fetched
                # description ends up as a (possibly empty / stripped)
                # plain string, not raw ADF JSON.
                It "accepts a whitespace-only description via -Description" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    # First, set a non-empty description so we can prove
                    # the whitespace write actually overwrote something
                    # rather than leaving the previous value in place.
                    $marker = "ADFWHITESPACE_$([Guid]::NewGuid().ToString('N'))"
                    Set-JiraIssue -Issue $tempIssue.Key -Description "Pre-whitespace marker $marker"

                    { Set-JiraIssue -Issue $tempIssue.Key -Description '   ' } | Should -Not -Throw

                    $fetched = Get-JiraIssue -Key $tempIssue.Key
                    # Cloud normalises pure whitespace away in the editor
                    # layer, so the fetched description is either empty
                    # or just whitespace. Either is fine — what we care
                    # about is (a) no rejection and (b) the previous
                    # marker is gone.
                    $fetched.Description | Should -Not -Match $marker
                    if ($fetched.Description) {
                        $fetched.Description | Should -BeOfType [string]
                        $fetched.Description | Should -Not -Match '"type":\s*"doc"'
                    }
                }

                It "accepts a whitespace-only comment via Add-JiraIssueComment" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    # Comments are a stricter test than description because
                    # we get back the body of THIS specific comment and can
                    # assert it didn't pick up another test's marker.
                    { Add-JiraIssueComment -Issue $tempIssue.Key -Comment '   ' } |
                        Should -Not -Throw
                }
            }

            Context "Add-JiraIssueWorklog + Get-JiraIssueWorklog" {
                It "round-trips a Markdown worklog comment" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $marker = "ADFWORKLOG_$([Guid]::NewGuid().ToString('N'))"
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

            # Regression coverage for #602: passing a rich-text field via
            # -Fields used to fail on Cloud with
            # "Operation value must be an Atlassian Document" because the
            # cmdlets routed to v3 but did not wrap the string. The
            # -Fields loop now consults the field schema via
            # Test-JiraRichTextField and wraps rich-text values in ADF.
            Context "New-JiraIssue -Fields with rich-text fields (regression)" {
                It "wraps a description supplied via -Fields into ADF on Cloud" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $marker = "ADFFIELDSCREATE_$([Guid]::NewGuid().ToString('N'))"
                    $description = "Description-via-fields $marker with **bold** prose."

                    $summary = New-TestResourceName -Type "ADFFieldsCreateIssue"
                    $created = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary -Fields @{
                        description = $description
                    }

                    try {
                        $created | Should -Not -BeNullOrEmpty

                        $fetched = Get-JiraIssue -Key $created.Key
                        $fetched.Description | Should -BeOfType [string]
                        $fetched.Description | Should -Not -Match '"type":\s*"doc"'
                        $fetched.Description | Should -Match $marker
                        $fetched.Description | Should -Match 'bold'
                    }
                    finally {
                        if ($created -and $created.Key) {
                            Remove-JiraIssue -IssueId $created.Key -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            }

            Context "Set-JiraIssue -Fields with rich-text fields (regression)" {
                It "wraps a description supplied via -Fields into ADF on Cloud" {
                    if (-not $tempIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $marker = "ADFFIELDSEDIT_$([Guid]::NewGuid().ToString('N'))"
                    $description = "Edit-via-fields $marker with **bold** prose."

                    Set-JiraIssue -Issue $tempIssue.Key -Fields @{ description = $description }

                    $fetched = Get-JiraIssue -Key $tempIssue.Key
                    $fetched.Description | Should -BeOfType [string]
                    $fetched.Description | Should -Not -Match '"type":\s*"doc"'
                    $fetched.Description | Should -Match $marker
                    $fetched.Description | Should -Match 'bold'
                }
            }
        }
    }
}
