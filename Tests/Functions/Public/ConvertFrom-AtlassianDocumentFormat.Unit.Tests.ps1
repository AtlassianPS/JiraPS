#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertFrom-AtlassianDocumentFormat" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Inline ADF fixtures ────────────────────────────────────

            $script:adfPlainParagraph = ConvertFrom-Json @'
{ "type": "doc", "version": 1, "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Hello world" }] }] }
'@
            $script:adfMultiParagraph = ConvertFrom-Json @'
{
  "type": "doc", "version": 1,
  "content": [
    { "type": "paragraph", "content": [{ "type": "text", "text": "First" }] },
    { "type": "paragraph", "content": [{ "type": "text", "text": "Second" }] }
  ]
}
'@

            $script:adfHeadings = ConvertFrom-Json @'
{
  "type": "doc", "version": 1,
  "content": [
    { "type": "heading", "attrs": { "level": 1 }, "content": [{ "type": "text", "text": "Header 1" }] },
    { "type": "heading", "attrs": { "level": 2 }, "content": [{ "type": "text", "text": "Header 2" }] },
    { "type": "heading", "attrs": { "level": 6 }, "content": [{ "type": "text", "text": "Header 6" }] }
  ]
}
'@

            $script:adfInlineMarks = ConvertFrom-Json @'
{
  "type": "doc", "version": 1,
  "content": [{
    "type": "paragraph",
    "content": [
      { "type": "text", "text": "plain " },
      { "type": "text", "text": "BOLD", "marks": [{ "type": "strong" }] },
      { "type": "text", "text": " " },
      { "type": "text", "text": "italic", "marks": [{ "type": "em" }] },
      { "type": "text", "text": " " },
      { "type": "text", "text": "struck", "marks": [{ "type": "strike" }] },
      { "type": "text", "text": " " },
      { "type": "text", "text": "code", "marks": [{ "type": "code" }] },
      { "type": "text", "text": " " },
      { "type": "text", "text": "underlined", "marks": [{ "type": "underline" }] }
    ]
  }]
}
'@

            $script:adfLink = ConvertFrom-Json @'
{
  "type": "doc", "version": 1,
  "content": [{
    "type": "paragraph",
    "content": [
      { "type": "text", "text": "click", "marks": [{ "type": "link", "attrs": { "href": "https://example.com" } }] }
    ]
  }]
}
'@

            $script:adfLists = ConvertFrom-Json @'
{
  "type": "doc", "version": 1,
  "content": [
    {
      "type": "bulletList",
      "content": [
        { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "alpha" }] }] },
        { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "beta" }] }] }
      ]
    },
    {
      "type": "orderedList", "attrs": { "order": 1 },
      "content": [
        { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "first" }] }] },
        { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "second" }] }] }
      ]
    },
    {
      "type": "taskList", "attrs": { "localId": "t1" },
      "content": [
        { "type": "taskItem", "attrs": { "localId": "i1", "state": "TODO" }, "content": [{ "type": "text", "text": "do this" }] },
        { "type": "taskItem", "attrs": { "localId": "i2", "state": "DONE" }, "content": [{ "type": "text", "text": "done that" }] }
      ]
    }
  ]
}
'@

            $script:adfBlocks = ConvertFrom-Json @'
{
  "type": "doc", "version": 1,
  "content": [
    { "type": "codeBlock", "attrs": { "language": "python" }, "content": [{ "type": "text", "text": "print(42)" }] },
    { "type": "blockquote", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "quoted" }] }] },
    {
      "type": "panel", "attrs": { "panelType": "info" },
      "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "info panel" }] }]
    }
  ]
}
'@

            $script:adfTable = ConvertFrom-Json @'
{
  "type": "doc", "version": 1,
  "content": [{
    "type": "table",
    "attrs": { "isNumberColumnEnabled": false, "layout": "align-start" },
    "content": [
      {
        "type": "tableRow",
        "content": [
          { "type": "tableHeader", "attrs": {}, "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Name" }] }] },
          { "type": "tableHeader", "attrs": {}, "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Value" }] }] }
        ]
      },
      {
        "type": "tableRow",
        "content": [
          { "type": "tableCell", "attrs": {}, "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "foo" }] }] },
          { "type": "tableCell", "attrs": {}, "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "bar" }] }] }
        ]
      }
    ]
  }]
}
'@

            $script:adfSpecialInline = ConvertFrom-Json @'
{
  "type": "doc", "version": 1,
  "content": [{
    "type": "paragraph",
    "content": [
      { "type": "mention", "attrs": { "id": "abc", "text": "@Oliver Lipkau", "accessLevel": "" } },
      { "type": "text", "text": " " },
      { "type": "emoji", "attrs": { "shortName": ":smiley:", "id": "1f603", "text": "\ud83d\ude03" } },
      { "type": "text", "text": " " },
      { "type": "date", "attrs": { "timestamp": "1775952000000" } }
    ]
  }]
}
'@

            $script:adfColoredText = ConvertFrom-Json @'
{
  "type": "doc", "version": 1,
  "content": [{
    "type": "paragraph",
    "content": [
      { "type": "text", "text": "blue", "marks": [{ "type": "textColor", "attrs": { "color": "#0747a6" } }] },
      { "type": "text", "text": " and " },
      { "type": "text", "text": "red", "marks": [{ "type": "textColor", "attrs": { "color": "#ff5630" } }] }
    ]
  }]
}
'@

            $script:adfSubSup = ConvertFrom-Json @'
{
  "type": "doc", "version": 1,
  "content": [{
    "type": "paragraph",
    "content": [
      { "type": "text", "text": "H" },
      { "type": "text", "text": "2", "marks": [{ "type": "subsup", "attrs": { "type": "sub" } }] },
      { "type": "text", "text": "O" }
    ]
  }]
}
'@

            $script:adfImage = ConvertFrom-Json @'
{
  "type": "doc", "version": 1,
  "content": [{
    "type": "mediaSingle", "attrs": { "layout": "align-start" },
    "content": [{
      "type": "media",
      "attrs": { "type": "external", "url": "https://example.com/image.png", "alt": "logo" }
    }]
  }]
}
'@

            $script:adfDecisionList = ConvertFrom-Json @'
{
  "type": "doc", "version": 1,
  "content": [{
    "type": "decisionList", "attrs": { "localId": "d1" },
    "content": [
      { "type": "decisionItem", "attrs": { "localId": "i1", "state": "DECIDED" }, "content": [{ "type": "text", "text": "accepted" }] }
    ]
  }]
}
'@
            #endregion
        }

        Context "Smoke test — real Jira Cloud ADF" {
            BeforeAll {
                $adfJson = Get-Content -Raw "$PSScriptRoot/../../Fixtures/adf.sample.json"
                $script:fullAdf = ConvertFrom-Json $adfJson
                $script:fullResult = ConvertFrom-AtlassianDocumentFormat -InputObject $fullAdf
            }

            It "returns a non-empty string" {
                $fullResult | Should -Not -BeNullOrEmpty
                $fullResult | Should -BeOfType [string]
            }

            It "contains Markdown heading markers" {
                $fullResult | Should -Match '(?m)^# '
                $fullResult | Should -Match '(?m)^###### '
            }

            It "contains bold and strikethrough markers" {
                $fullResult | Should -Match '\*\*.+\*\*'
                $fullResult | Should -Match '~~.+~~'
            }

            It "contains bullet and ordered list markers" {
                $fullResult | Should -Match '(?m)^\* '
                $fullResult | Should -Match '(?m)^\d+\. '
            }

            It "contains a code fence" {
                $fullResult | Should -Match '(?m)^```\w+$'
            }

            It "contains a blockquote marker" {
                $fullResult | Should -Match '(?m)^> '
            }

            It "contains table pipe delimiters" {
                $fullResult | Should -Match '(?m)^\|.+\|$'
            }
        }

        Context "Input handling" {
            It "returns a plain string unchanged" {
                ConvertFrom-AtlassianDocumentFormat -InputObject "plain text" | Should -Be "plain text"
            }

            It "returns an empty string unchanged" {
                ConvertFrom-AtlassianDocumentFormat -InputObject "" | Should -Be ""
            }

            It "returns null for null input" {
                ConvertFrom-AtlassianDocumentFormat -InputObject $null | Should -BeNullOrEmpty
            }

            It "always returns a [string] for ADF input" {
                ConvertFrom-AtlassianDocumentFormat -InputObject $adfPlainParagraph | Should -BeOfType [string]
            }
        }

        Context "Basic structure" {
            It "extracts text from a single paragraph" {
                ConvertFrom-AtlassianDocumentFormat -InputObject $adfPlainParagraph | Should -Be "Hello world"
            }

            It "separates multiple paragraphs with a blank line" {
                $result = ConvertFrom-AtlassianDocumentFormat -InputObject $adfMultiParagraph
                $result | Should -Be "First`n`nSecond"
            }
        }

        Context "Headings" {
            BeforeAll { $script:h = ConvertFrom-AtlassianDocumentFormat -InputObject $adfHeadings }

            It "renders H1 with a single hash" {
                $h | Should -Match '(?m)^# Header 1$'
            }

            It "renders H2 with two hashes" {
                $h | Should -Match '(?m)^## Header 2$'
            }

            It "renders H6 with six hashes" {
                $h | Should -Match '(?m)^###### Header 6$'
            }
        }

        Context "Inline marks" {
            BeforeAll { $script:inl = ConvertFrom-AtlassianDocumentFormat -InputObject $adfInlineMarks }

            It "renders strong mark as **text**" {
                $inl | Should -Match '\*\*BOLD\*\*'
            }

            It "renders em mark as _text_" {
                $inl | Should -Match '_italic_'
            }

            It "renders strike mark as ~~text~~" {
                $inl | Should -Match '~~struck~~'
            }

            It 'renders code mark as `text`' {
                $inl | Should -Match '`code`'
            }

            It "renders underline as plain text (no HTML tag)" {
                $inl | Should -Match '\bunderlined\b'
                $inl | Should -Not -Match '<u>'
            }
        }

        Context "Unsupported marks (graceful fallback)" {
            It "renders textColor-marked text as plain text" {
                $result = ConvertFrom-AtlassianDocumentFormat -InputObject $adfColoredText
                $result | Should -Be 'blue and red'
            }

            It "renders subscript as plain text" {
                $result = ConvertFrom-AtlassianDocumentFormat -InputObject $adfSubSup
                $result | Should -Be 'H2O'
            }
        }

        Context "Links" {
            It 'renders a link mark as [text](url)' {
                $result = ConvertFrom-AtlassianDocumentFormat -InputObject $adfLink
                $result | Should -Be '[click](https://example.com)'
            }
        }

        Context "Lists" {
            BeforeAll { $script:lst = ConvertFrom-AtlassianDocumentFormat -InputObject $adfLists }

            It "renders bullet list items with * prefix" {
                $lst | Should -Match '(?m)^\* alpha$'
                $lst | Should -Match '(?m)^\* beta$'
            }

            It "renders ordered list items with sequential N. prefix" {
                $lst | Should -Match '(?m)^1\. first$'
                $lst | Should -Match '(?m)^2\. second$'
            }

            It "renders unchecked task items as '* [ ] text'" {
                $lst | Should -Match '(?m)^\* \[ \] do this$'
            }

            It "renders checked task items as '* [x] text'" {
                $lst | Should -Match '(?m)^\* \[x\] done that$'
            }
        }

        Context "Block types" {
            BeforeAll { $script:blk = ConvertFrom-AtlassianDocumentFormat -InputObject $adfBlocks }

            It "renders code block with opening and closing fences" {
                $blk | Should -Match '(?m)^```python$'
                $blk | Should -Match 'print\(42\)'
                $blk | Should -Match '(?m)^```$'
            }

            It "renders blockquote lines with > prefix" {
                $blk | Should -Match '(?m)^> quoted$'
            }

            It "renders panel content as plain text (no wrapper)" {
                $blk | Should -Match '\binfo panel\b'
            }
        }

        Context "Table" {
            BeforeAll {
                $script:tbl = ConvertFrom-AtlassianDocumentFormat -InputObject $adfTable
                $script:tblLines = $tbl -split "`n"
            }

            It "renders header row with pipe delimiters" {
                $tblLines[0] | Should -Be '| Name | Value |'
            }

            It "renders a separator row after the header" {
                $tblLines[1] | Should -Match '^\| -{3,} \| -{3,} \|$'
            }

            It "renders data row with pipe delimiters" {
                $tblLines[2] | Should -Be '| foo | bar |'
            }

            It "produces exactly 3 lines (header + separator + data)" {
                $tblLines | Should -HaveCount 3
            }
        }

        Context "Special inline nodes" {
            BeforeAll { $script:spc = ConvertFrom-AtlassianDocumentFormat -InputObject $adfSpecialInline }

            It "renders mention using attrs.text" {
                $spc | Should -Match '@Oliver Lipkau'
            }

            It "renders emoji using attrs.text" {
                $spc | Should -Match ([regex]::Escape('😃'))
            }

            It "renders date as ISO 8601 string (yyyy-MM-dd)" {
                $spc | Should -Match '\d{4}-\d{2}-\d{2}'
            }
        }

        Context "Image (mediaSingle)" {
            It 'renders as ![alt](url)' {
                $result = ConvertFrom-AtlassianDocumentFormat -InputObject $adfImage
                $result | Should -Be '![logo](https://example.com/image.png)'
            }
        }

        Context "Decision list" {
            It "renders decision item text" {
                $result = ConvertFrom-AtlassianDocumentFormat -InputObject $adfDecisionList
                $result | Should -Be 'accepted'
            }
        }

        Context "Negative / edge cases" {
            It "returns the string representation of a numeric input" {
                $result = ConvertFrom-AtlassianDocumentFormat -InputObject 42
                $result | Should -BeOfType [string]
                $result | Should -Be "42"
            }

            It "returns empty/null for an ADF doc with empty content array" {
                $emptyDoc = [PSCustomObject]@{ type = 'doc'; version = 1; content = @() }
                ConvertFrom-AtlassianDocumentFormat -InputObject $emptyDoc | Should -BeNullOrEmpty
            }

            It "does not throw for an ADF doc with no content property" {
                $noContent = [PSCustomObject]@{ type = 'doc'; version = 1 }
                { ConvertFrom-AtlassianDocumentFormat -InputObject $noContent } | Should -Not -Throw
            }

            It "silently skips unknown node types without losing subsequent nodes" {
                $doc = [PSCustomObject]@{
                    type = 'doc'; version = 1
                    content = @(
                        [PSCustomObject]@{ type = 'unknownWidget' },
                        [PSCustomObject]@{
                            type    = 'paragraph'
                            content = @([PSCustomObject]@{ type = 'text'; text = 'after unknown' })
                        }
                    )
                }
                $result = ConvertFrom-AtlassianDocumentFormat -InputObject $doc
                $result | Should -Be 'after unknown'
            }

            It "does not throw for a heading with no content array" {
                $doc = [PSCustomObject]@{
                    type = 'doc'; version = 1
                    content = @(
                        [PSCustomObject]@{ type = 'heading'; attrs = @{ level = 1 } }
                    )
                }
                { ConvertFrom-AtlassianDocumentFormat -InputObject $doc } | Should -Not -Throw
            }

            It "skips paragraphs with null content" {
                $doc = [PSCustomObject]@{
                    type = 'doc'; version = 1
                    content = @(
                        [PSCustomObject]@{ type = 'paragraph'; content = $null },
                        [PSCustomObject]@{
                            type    = 'paragraph'
                            content = @([PSCustomObject]@{ type = 'text'; text = 'visible' })
                        }
                    )
                }
                $result = ConvertFrom-AtlassianDocumentFormat -InputObject $doc
                $result | Should -Be 'visible'
            }
        }

        Context "Pipeline support" {
            It "accepts input from the pipeline" {
                "hello" | ConvertFrom-AtlassianDocumentFormat | Should -Be "hello"
            }

            It "processes multiple ADF objects from the pipeline" {
                $results = $adfPlainParagraph, "plain" | ConvertFrom-AtlassianDocumentFormat
                $results | Should -HaveCount 2
                $results[0] | Should -Be "Hello world"
                $results[1] | Should -Be "plain"
            }
        }
    }
}
