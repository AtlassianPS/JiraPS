#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-AtlassianDocumentFormat" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            # Load the sample Markdown from the project root
            $script:sampleMd = Get-Content -Raw "$PSScriptRoot/../../Fixtures/adf.sample.md"

            # Helper: find all nodes of a given type anywhere in a doc (depth-first)
            function script:Find-AdfNode {
                param($Doc, [string]$Type)
                $results = [System.Collections.Generic.List[object]]::new()
                function recurse($node) {
                    if ($node -is [hashtable] -and $node.type -eq $Type) { $results.Add($node) }
                    if ($node -is [hashtable] -and $node.ContainsKey('content') -and $node.content) {
                        foreach ($c in $node.content) { recurse $c }
                    }
                }
                foreach ($n in $Doc.content) { recurse $n }
                $results
            }
        }

        Context "Input handling" {
            It "returns a doc with type = 'doc' and version = 1" {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown "hello"
                $result.type    | Should -Be "doc"
                $result.version | Should -Be 1
            }

            It "returns an empty content array for an empty string" {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown ""
                $result.content | Should -HaveCount 0
            }

            It "returns an empty content array for whitespace-only input" {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown "   "
                $result.content | Should -HaveCount 0
            }

            It "accepts input from the pipeline" {
                $result = "hello" | ConvertTo-AtlassianDocumentFormat
                $result.type | Should -Be "doc"
            }
        }

        Context "Headings" {
            It "converts '<md>' to a heading node with level <level>" -TestCases @(
                @{ level = 1; md = '# Header 1'; text = 'Header 1' }
                @{ level = 2; md = '## Header 2'; text = 'Header 2' }
                @{ level = 3; md = '### Header 3'; text = 'Header 3' }
                @{ level = 4; md = '#### Header 4'; text = 'Header 4' }
                @{ level = 5; md = '##### Header 5'; text = 'Header 5' }
                @{ level = 6; md = '###### Header 6'; text = 'Header 6' }
            ) {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown $md
                $node = $result.content[0]
                $node.type          | Should -Be "heading"
                $node.attrs.level   | Should -Be $level
                $node.content[0].text | Should -Be $text
            }
        }

        Context "Paragraph" {
            It "converts a plain text line to a paragraph node" {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown "Normal text"
                $result.content[0].type             | Should -Be "paragraph"
                $result.content[0].content[0].type  | Should -Be "text"
                $result.content[0].content[0].text  | Should -Be "Normal text"
            }

            It "emits separate paragraph nodes for lines separated by a blank line" {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown "First`n`nSecond"
                $result.content | Should -HaveCount 2
                $result.content[0].type | Should -Be "paragraph"
                $result.content[1].type | Should -Be "paragraph"
            }
        }

        Context "Inline marks" {
            It "converts **text** to a text node with 'strong' mark" {
                $nodes = (ConvertTo-AtlassianDocumentFormat -Markdown "**bold**").content[0].content
                $node = $nodes | Where-Object { $_.text -eq 'bold' }
                $node.marks[0].type | Should -Be "strong"
            }

            It "converts _text_ to a text node with 'em' mark" {
                $nodes = (ConvertTo-AtlassianDocumentFormat -Markdown "_italic_").content[0].content
                $node = $nodes | Where-Object { $_.text -eq 'italic' }
                $node.marks[0].type | Should -Be "em"
            }

            It "converts ~~text~~ to a text node with 'strike' mark" {
                $nodes = (ConvertTo-AtlassianDocumentFormat -Markdown "~~struck~~").content[0].content
                $node = $nodes | Where-Object { $_.text -eq 'struck' }
                $node.marks[0].type | Should -Be "strike"
            }

            It "converts `text` to a text node with 'code' mark" {
                $nodes = (ConvertTo-AtlassianDocumentFormat -Markdown '`code`').content[0].content
                $node = $nodes | Where-Object { $_.text -eq 'code' }
                $node.marks[0].type | Should -Be "code"
            }

            It 'converts [text](url) to a text node with a link mark' {
                $nodes = (ConvertTo-AtlassianDocumentFormat -Markdown '[GitHub](https://github.com)').content[0].content
                $node = $nodes | Where-Object { $_.text -eq 'GitHub' }
                $node.marks[0].type | Should -Be "link"
                $node.marks[0].attrs.href | Should -Be "https://github.com"
            }

            It "preserves surrounding plain text alongside marked text" {
                $nodes = (ConvertTo-AtlassianDocumentFormat -Markdown "Plain **bold** end").content[0].content
                ($nodes | Where-Object { $_.text -eq 'Plain ' }) | Should -Not -BeNullOrEmpty
                ($nodes | Where-Object { $_.text -eq ' end' })   | Should -Not -BeNullOrEmpty
            }

            It "converts ***text*** to a text node with both 'strong' and 'em' marks" {
                $nodes = (ConvertTo-AtlassianDocumentFormat -Markdown "***bold italic***").content[0].content
                $node = $nodes | Where-Object { $_.text -eq 'bold italic' }
                $node.marks | Should -HaveCount 2
                ($node.marks | Where-Object { $_.type -eq 'strong' }) | Should -Not -BeNullOrEmpty
                ($node.marks | Where-Object { $_.type -eq 'em' }) | Should -Not -BeNullOrEmpty
            }

            It "converts **_text_** to a text node with both 'strong' and 'em' marks" {
                $nodes = (ConvertTo-AtlassianDocumentFormat -Markdown "**_nested marks_**").content[0].content
                $node = $nodes | Where-Object { $_.text -eq 'nested marks' }
                $node.marks | Should -HaveCount 2
                ($node.marks | Where-Object { $_.type -eq 'strong' }) | Should -Not -BeNullOrEmpty
                ($node.marks | Where-Object { $_.type -eq 'em' }) | Should -Not -BeNullOrEmpty
            }

            It "converts _**text**_ to a text node with both 'em' and 'strong' marks" {
                $nodes = (ConvertTo-AtlassianDocumentFormat -Markdown "_**italic bold**_").content[0].content
                $node = $nodes | Where-Object { $_.text -eq 'italic bold' }
                $node.marks | Should -HaveCount 2
                ($node.marks | Where-Object { $_.type -eq 'em' }) | Should -Not -BeNullOrEmpty
                ($node.marks | Where-Object { $_.type -eq 'strong' }) | Should -Not -BeNullOrEmpty
            }
        }

        Context "Bullet list" {
            BeforeAll {
                $script:blResult = ConvertTo-AtlassianDocumentFormat -Markdown "* unordered`n* bullet`n* list"
            }

            It "produces a bulletList node" {
                $blResult.content[0].type | Should -Be "bulletList"
            }

            It "produces 3 listItem nodes" {
                $blResult.content[0].content | Should -HaveCount 3
            }

            It "each listItem wraps its text in a paragraph" {
                foreach ($item in $blResult.content[0].content) {
                    $item.type                      | Should -Be "listItem"
                    $item.content[0].type           | Should -Be "paragraph"
                    $item.content[0].content[0].type | Should -Be "text"
                }
            }

            It "listItem '<index>' has text '<text>'" -TestCases @(
                @{ index = 0; text = 'unordered' }
                @{ index = 1; text = 'bullet' }
                @{ index = 2; text = 'list' }
            ) {
                $blResult.content[0].content[$index].content[0].content[0].text | Should -Be $text
            }
        }

        Context "Ordered list" {
            BeforeAll {
                $script:olResult = ConvertTo-AtlassianDocumentFormat -Markdown "1. ordered`n2. bullet list"
            }

            It "produces an orderedList node" {
                $olResult.content[0].type | Should -Be "orderedList"
            }

            It "sets attrs.order = 1" {
                $olResult.content[0].attrs.order | Should -Be 1
            }

            It "produces 2 listItem nodes" {
                $olResult.content[0].content | Should -HaveCount 2
            }

            It "listItem '<index>' has text '<text>'" -TestCases @(
                @{ index = 0; text = 'ordered' }
                @{ index = 1; text = 'bullet list' }
            ) {
                $olResult.content[0].content[$index].content[0].content[0].text | Should -Be $text
            }
        }

        Context "Nested lists (2 levels)" {
            BeforeAll {
                $script:nestedBullet = ConvertTo-AtlassianDocumentFormat -Markdown "* parent`n  * nested child`n* another parent"
                $script:nestedOrdered = ConvertTo-AtlassianDocumentFormat -Markdown "1. first`n  1. nested first`n  2. nested second`n2. second"
                $script:mixedNested = ConvertTo-AtlassianDocumentFormat -Markdown "* bullet parent`n  1. ordered nested"
            }

            It "produces a bulletList with nested bulletList" {
                $nestedBullet.content[0].type | Should -Be "bulletList"
                # First item should have nested list
                $firstItem = $nestedBullet.content[0].content[0]
                $firstItem.content | Should -HaveCount 2
                $firstItem.content[0].type | Should -Be "paragraph"
                $firstItem.content[1].type | Should -Be "bulletList"
            }

            It "nested bullet list contains the child item" {
                $nestedList = $nestedBullet.content[0].content[0].content[1]
                $nestedList.content[0].content[0].content[0].text | Should -Be "nested child"
            }

            It "parent list has 2 items (parent items only)" {
                $nestedBullet.content[0].content | Should -HaveCount 2
            }

            It "produces an orderedList with nested orderedList" {
                $nestedOrdered.content[0].type | Should -Be "orderedList"
                $firstItem = $nestedOrdered.content[0].content[0]
                $firstItem.content | Should -HaveCount 2
                $firstItem.content[1].type | Should -Be "orderedList"
            }

            It "nested ordered list has 2 items" {
                $nestedList = $nestedOrdered.content[0].content[0].content[1]
                $nestedList.content | Should -HaveCount 2
            }

            It "supports mixed nesting (bullet parent with ordered nested)" {
                $mixedNested.content[0].type | Should -Be "bulletList"
                $mixedNested.content[0].content[0].content[1].type | Should -Be "orderedList"
            }

            It "nested list round-trips through ConvertFrom-AtlassianDocumentFormat" {
                $md = "* parent`n  * nested"
                $adf = ConvertTo-AtlassianDocumentFormat -Markdown $md
                $back = ConvertFrom-AtlassianDocumentFormat -InputObject $adf
                $back | Should -Match '(?m)^\* parent$'
                $back | Should -Match '(?m)^  \* nested$'
            }
        }

        Context "Task list" {
            BeforeAll {
                $script:tlResult = ConvertTo-AtlassianDocumentFormat -Markdown "* [ ] todo item`n* [x] done item"
            }

            It "produces a taskList node" {
                $tlResult.content[0].type | Should -Be "taskList"
            }

            It "sets taskList attrs.localId" {
                $tlResult.content[0].attrs.localId | Should -Not -BeNullOrEmpty
            }

            It "sets state = TODO for an unchecked item '* [ ]'" {
                $tlResult.content[0].content[0].attrs.state | Should -Be "TODO"
            }

            It "sets state = DONE for a checked item '* [x]'" {
                $tlResult.content[0].content[1].attrs.state | Should -Be "DONE"
            }

            It "each taskItem has a unique localId" {
                $ids = $tlResult.content[0].content | ForEach-Object { $_.attrs.localId }
                $ids | Select-Object -Unique | Should -HaveCount 2
            }
        }

        Context "Code block" {
            BeforeAll {
                $script:cbResult = ConvertTo-AtlassianDocumentFormat -Markdown @'
```python
import os

print(os.path('.'))
```
'@
            }

            It "produces a codeBlock node" {
                $cbResult.content[0].type | Should -Be "codeBlock"
            }

            It "sets the language attribute from the fence" {
                $cbResult.content[0].attrs.language | Should -Be "python"
            }

            It "preserves the code content including internal newlines" {
                $cbResult.content[0].content[0].text | Should -Match 'import os'
                $cbResult.content[0].content[0].text | Should -Match "print\(os\.path"
            }
        }

        Context "Blockquote" {
            BeforeAll {
                $script:bqResult = ConvertTo-AtlassianDocumentFormat -Markdown "> quote text"
            }

            It "produces a blockquote node" {
                $bqResult.content[0].type | Should -Be "blockquote"
            }

            It "wraps the quoted text in a paragraph" {
                $bqResult.content[0].content[0].type | Should -Be "paragraph"
            }

            It "contains the quoted text" {
                $bqResult.content[0].content[0].content[0].text | Should -Be "quote text"
            }
        }

        Context "Table" {
            BeforeAll {
                $script:tblResult = ConvertTo-AtlassianDocumentFormat -Markdown @'
| Table | with | header |
| ----- | ---- | ------ |
| lorem | ipsum | dolor |
'@
            }

            It "produces a table node" {
                $tblResult.content[0].type | Should -Be "table"
            }

            It "produces 2 tableRow nodes (separator excluded)" {
                $tblResult.content[0].content | Should -HaveCount 2
            }

            It "header row uses tableHeader cell type" {
                $tblResult.content[0].content[0].content[0].type | Should -Be "tableHeader"
            }

            It "data row uses tableCell cell type" {
                $tblResult.content[0].content[1].content[0].type | Should -Be "tableCell"
            }

            It "header cell '<index>' contains text '<text>'" -TestCases @(
                @{ index = 0; text = 'Table' }
                @{ index = 1; text = 'with' }
                @{ index = 2; text = 'header' }
            ) {
                $tblResult.content[0].content[0].content[$index].content[0].content[0].text |
                    Should -Be $text
            }

            It "data cell '<index>' contains text '<text>'" -TestCases @(
                @{ index = 0; text = 'lorem' }
                @{ index = 1; text = 'ipsum' }
                @{ index = 2; text = 'dolor' }
            ) {
                $tblResult.content[0].content[1].content[$index].content[0].content[0].text |
                    Should -Be $text
            }
        }

        Context "Block image (mediaSingle)" {
            BeforeAll {
                $script:imgResult = ConvertTo-AtlassianDocumentFormat -Markdown "![alt text](https://example.com/img.png)"
            }

            It "produces a mediaSingle node" {
                $imgResult.content[0].type | Should -Be "mediaSingle"
            }

            It "contains a media child with type = external" {
                $imgResult.content[0].content[0].type              | Should -Be "media"
                $imgResult.content[0].content[0].attrs.type        | Should -Be "external"
            }

            It "stores the image URL in attrs.url" {
                $imgResult.content[0].content[0].attrs.url | Should -Be "https://example.com/img.png"
            }

            It "stores the alt text in attrs.alt" {
                $imgResult.content[0].content[0].attrs.alt | Should -Be "alt text"
            }
        }

        Context "Round-trip via ConvertFrom-AtlassianDocumentFormat" {
            It "Markdown heading survives ADF round-trip" {
                $md = "# Header 1"
                $adf = ConvertTo-AtlassianDocumentFormat -Markdown $md
                $back = ConvertFrom-AtlassianDocumentFormat -InputObject $adf
                $back | Should -Match '(?m)^# Header 1$'
            }

            It "bold inline survives ADF round-trip" {
                $md = "Plain **bold** end"
                $adf = ConvertTo-AtlassianDocumentFormat -Markdown $md
                $back = ConvertFrom-AtlassianDocumentFormat -InputObject $adf
                $back | Should -Match '\*\*bold\*\*'
            }

            It "link survives ADF round-trip" {
                $md = '[GitHub](https://github.com)'
                $adf = ConvertTo-AtlassianDocumentFormat -Markdown $md
                $back = ConvertFrom-AtlassianDocumentFormat -InputObject $adf
                $back | Should -Be '[GitHub](https://github.com)'
            }

            It "bullet list survives ADF round-trip" {
                $md = "* alpha`n* beta"
                $adf = ConvertTo-AtlassianDocumentFormat -Markdown $md
                $back = ConvertFrom-AtlassianDocumentFormat -InputObject $adf
                $back | Should -Match '(?m)^\* alpha$'
                $back | Should -Match '(?m)^\* beta$'
            }

            It "ordered list survives ADF round-trip" {
                $md = "1. first`n2. second"
                $adf = ConvertTo-AtlassianDocumentFormat -Markdown $md
                $back = ConvertFrom-AtlassianDocumentFormat -InputObject $adf
                $back | Should -Match '(?m)^1\. first$'
                $back | Should -Match '(?m)^2\. second$'
            }

            It "unchecked task list item survives ADF round-trip" {
                $md = "* [ ] do this"
                $adf = ConvertTo-AtlassianDocumentFormat -Markdown $md
                $back = ConvertFrom-AtlassianDocumentFormat -InputObject $adf
                $back | Should -Match '(?m)^\* \[ \] do this$'
            }

            It "code block survives ADF round-trip" {
                $md = @'
```python
print("hello")
```
'@
                $adf = ConvertTo-AtlassianDocumentFormat -Markdown $md
                $back = ConvertFrom-AtlassianDocumentFormat -InputObject $adf
                $back | Should -Match '(?m)^```python$'
                $back | Should -Match 'print\("hello"\)'
                $back | Should -Match '(?m)^```$'
            }

            It "table survives ADF round-trip" {
                $md = "| A | B |`n| -- | -- |`n| 1 | 2 |"
                $adf = ConvertTo-AtlassianDocumentFormat -Markdown $md
                $back = ConvertFrom-AtlassianDocumentFormat -InputObject $adf
                $back | Should -Match '\| A \|'
                $back | Should -Match '\| 1 \|'
            }
        }

        Context "Sample file — all heading levels present" {
            BeforeAll {
                $script:sampleResult = ConvertTo-AtlassianDocumentFormat -Markdown $sampleMd
                $script:sampleHeadings = Find-AdfNode -Doc $sampleResult -Type 'heading'
            }

            It "produces heading nodes for all 6 levels" {
                $levels = $sampleHeadings | ForEach-Object { $_.attrs.level } | Sort-Object -Unique
                $levels | Should -HaveCount 6
            }

            It "heading for level <level> has text 'Header <level>'" -TestCases @(
                @{ level = 1 }; @{ level = 2 }; @{ level = 3 }
                @{ level = 4 }; @{ level = 5 }; @{ level = 6 }
            ) {
                $node = $sampleHeadings | Where-Object { $_.attrs.level -eq $level } | Select-Object -First 1
                $node | Should -Not -BeNullOrEmpty
                $node.content[0].text | Should -Be "Header $level"
            }
        }

        Context "Sample file — list types present" {
            BeforeAll {
                $script:sampleFromMd = ConvertTo-AtlassianDocumentFormat -Markdown $sampleMd
            }

            It "produces a bulletList node" {
                (Find-AdfNode -Doc $sampleFromMd -Type 'bulletList') | Should -Not -BeNullOrEmpty
            }

            It "produces an orderedList node" {
                (Find-AdfNode -Doc $sampleFromMd -Type 'orderedList') | Should -Not -BeNullOrEmpty
            }

            It "produces a taskList node" {
                (Find-AdfNode -Doc $sampleFromMd -Type 'taskList') | Should -Not -BeNullOrEmpty
            }
        }

        Context "Hard breaks (trailing double-space)" {
            It "converts trailing double-space to a hardBreak node" {
                # Two spaces at end of line followed by another line = hard break
                $result = ConvertTo-AtlassianDocumentFormat -Markdown "line one  `nline two"
                $result.content | Should -HaveCount 1
                $result.content[0].type | Should -Be "paragraph"
                $result.content[0].content | Should -HaveCount 3
                $result.content[0].content[0].text | Should -Be "line one"
                $result.content[0].content[1].type | Should -Be "hardBreak"
                $result.content[0].content[2].text | Should -Be "line two"
            }

            It "handles multiple consecutive hard breaks" {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown "first  `nsecond  `nthird"
                $result.content | Should -HaveCount 1
                $result.content[0].content | Should -HaveCount 5
                $result.content[0].content[0].text | Should -Be "first"
                $result.content[0].content[1].type | Should -Be "hardBreak"
                $result.content[0].content[2].text | Should -Be "second"
                $result.content[0].content[3].type | Should -Be "hardBreak"
                $result.content[0].content[4].text | Should -Be "third"
            }

            It "does not add hardBreak when line ends normally (no trailing spaces)" {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown "line one`n`nline two"
                $result.content | Should -HaveCount 2
                $result.content[0].content[0].text | Should -Be "line one"
                $result.content[1].content[0].text | Should -Be "line two"
            }

            It "hardBreak round-trips through ConvertFrom-AtlassianDocumentFormat" {
                $md = "line one  `nline two"
                $adf = ConvertTo-AtlassianDocumentFormat -Markdown $md
                $back = ConvertFrom-AtlassianDocumentFormat -InputObject $adf
                $back | Should -Match 'line one'
                $back | Should -Match 'line two'
            }
        }

        Context "Negative / edge cases" {
            It "handles an unclosed code fence without throwing" {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown "``````python`nprint('hi')"
                $result.content[0].type | Should -Be "codeBlock"
                $result.content[0].attrs.language | Should -Be "python"
                $result.content[0].content[0].text | Should -Be "print('hi')"
            }

            It "handles a table with only a header row (no data)" {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown "| A | B |`n| -- | -- |"
                $result.content[0].type | Should -Be "table"
                $result.content[0].content | Should -HaveCount 1
                $result.content[0].content[0].content[0].type | Should -Be "tableHeader"
            }

            It "does not produce empty paragraph nodes for multiple blank lines" {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown "First`n`n`n`nSecond"
                $result.content | Should -HaveCount 2
                $result.content[0].content[0].text | Should -Be "First"
                $result.content[1].content[0].text | Should -Be "Second"
            }

            It "handles an image with empty alt text" {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown '![](https://example.com/img.png)'
                $result.content[0].type | Should -Be "mediaSingle"
                $result.content[0].content[0].attrs.url | Should -Be "https://example.com/img.png"
                $result.content[0].content[0].attrs.alt | Should -Be ""
            }

            It "splits marked text correctly at word boundaries" {
                $nodes = (ConvertTo-AtlassianDocumentFormat -Markdown "**bold**rest").content[0].content
                ($nodes | Where-Object { $_.text -eq 'bold' }).marks[0].type | Should -Be "strong"
                ($nodes | Where-Object { $_.text -eq 'rest' }).marks | Should -BeNullOrEmpty
            }

            It "handles input with only special characters" {
                $result = ConvertTo-AtlassianDocumentFormat -Markdown '!@$%^&'
                $result.content[0].type | Should -Be "paragraph"
                $result.content[0].content[0].type | Should -Be "text"
            }
        }
    }
}
