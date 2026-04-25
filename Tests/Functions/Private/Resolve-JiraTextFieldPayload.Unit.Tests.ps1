#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Resolve-JiraTextFieldPayload" -Tag 'Unit' {

        Context "Jira Server / Data Center" {
            It "returns the input string verbatim" {
                $result = Resolve-JiraTextFieldPayload -Text 'Hello *world*' -IsCloud $false
                $result | Should -BeOfType [string]
                $result | Should -Be 'Hello *world*'
            }

            It "preserves wiki-markup unchanged" {
                $wiki = "h1. Heading`n||a||b||`n|1|2|"
                $result = Resolve-JiraTextFieldPayload -Text $wiki -IsCloud $false
                $result | Should -Be $wiki
            }

            It "returns an empty string verbatim" {
                $result = Resolve-JiraTextFieldPayload -Text '' -IsCloud $false
                $result | Should -BeOfType [string]
                $result | Should -Be ''
            }

            It "does not warn about wiki-markup tables on Server / DC" {
                $warnings = $null
                $null = Resolve-JiraTextFieldPayload -Text "||a||b||`n|1|2|" -IsCloud $false -WarningVariable warnings -WarningAction SilentlyContinue
                $warnings | Should -BeNullOrEmpty
            }
        }

        Context "Jira Cloud" {
            It "wraps Markdown into an ADF document hashtable" {
                $result = Resolve-JiraTextFieldPayload -Text 'Hello world' -IsCloud $true
                $result | Should -BeOfType [hashtable]
                $result.type | Should -Be 'doc'
                $result.version | Should -Be 1
                $result.content.Count | Should -Be 1
                $result.content[0].type | Should -Be 'paragraph'
                $result.content[0].content[0].text | Should -Be 'Hello world'
            }

            It "produces ADF nodes for richer Markdown (heading + paragraph)" {
                $result = Resolve-JiraTextFieldPayload -Text "# Title`n`nBody" -IsCloud $true
                $result.content.Count | Should -Be 2
                $result.content[0].type | Should -Be 'heading'
                $result.content[1].type | Should -Be 'paragraph'
            }

            It "round-trips through ConvertFrom-AtlassianDocumentFormat" {
                $original = "Plain paragraph with *italic* text."
                $adf = Resolve-JiraTextFieldPayload -Text $original -IsCloud $true
                $rendered = ConvertFrom-AtlassianDocumentFormat -InputObject $adf
                $rendered | Should -Be $original
            }

            It "returns an empty string verbatim (text node cannot be empty)" {
                $result = Resolve-JiraTextFieldPayload -Text '' -IsCloud $true
                $result | Should -BeOfType [string]
                $result | Should -Be ''
            }

            It "wraps a whitespace-only string in a single ADF paragraph" {
                $whitespace = "   `n  "
                $result = Resolve-JiraTextFieldPayload -Text $whitespace -IsCloud $true

                $result | Should -BeOfType [hashtable]
                $result.type | Should -Be 'doc'
                $result.version | Should -Be 1
                $result.content.Count | Should -Be 1
                $result.content[0].type | Should -Be 'paragraph'
                $result.content[0].content[0].type | Should -Be 'text'
                $result.content[0].content[0].text | Should -Be $whitespace
            }

            It "wraps a single space in an ADF paragraph (preserves caller intent)" {
                $result = Resolve-JiraTextFieldPayload -Text ' ' -IsCloud $true
                $result | Should -BeOfType [hashtable]
                $result.content[0].content[0].text | Should -Be ' '
            }

            It "returns `$null verbatim" {
                $result = Resolve-JiraTextFieldPayload -Text $null -IsCloud $true
                $result | Should -BeNullOrEmpty
            }

            It "warns when input contains a wiki-markup table header (||header||)" {
                $warnings = $null
                $null = Resolve-JiraTextFieldPayload -Text "||a||b||`n|1|2|" -IsCloud $true -WarningVariable warnings -WarningAction SilentlyContinue
                $warnings | Should -Not -BeNullOrEmpty
                ($warnings | Out-String) | Should -Match 'wiki-markup table'
            }

            It "warns even when the wiki-table header is indented" {
                $warnings = $null
                $null = Resolve-JiraTextFieldPayload -Text "  ||a||b||`n  |1|2|" -IsCloud $true -WarningVariable warnings -WarningAction SilentlyContinue
                $warnings | Should -Not -BeNullOrEmpty
            }

            It "does not warn for valid Markdown tables" {
                $warnings = $null
                $null = Resolve-JiraTextFieldPayload -Text "| a | b |`n| --- | --- |`n| 1 | 2 |" -IsCloud $true -WarningVariable warnings -WarningAction SilentlyContinue
                $warnings | Should -BeNullOrEmpty
            }

            It "does not warn for prose that contains a single pipe in the middle of a line" {
                $warnings = $null
                $null = Resolve-JiraTextFieldPayload -Text "use the | operator to pipe output" -IsCloud $true -WarningVariable warnings -WarningAction SilentlyContinue
                $warnings | Should -BeNullOrEmpty
            }

            It "does not warn for a Markdown-style data row without a header / separator (no double-pipe)" {
                # Single-pipe rows are ambiguous (could be a misformatted Markdown
                # table or a wiki-markup data row). The tightened heuristic only
                # fires on the unambiguous `||header||` form, so this passes
                # through silently — the converter does the right thing for real
                # Markdown tables and the worst case for malformed input is a
                # paragraph that renders the literal pipes.
                $warnings = $null
                $null = Resolve-JiraTextFieldPayload -Text "|cell1|cell2|" -IsCloud $true -WarningVariable warnings -WarningAction SilentlyContinue
                $warnings | Should -BeNullOrEmpty
            }

            It "does not warn for plain prose" {
                $warnings = $null
                $null = Resolve-JiraTextFieldPayload -Text "Just a plain comment with no tables." -IsCloud $true -WarningVariable warnings -WarningAction SilentlyContinue
                $warnings | Should -BeNullOrEmpty
            }
        }
    }
}
