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

            It "returns an empty string verbatim (does not wrap)" {
                $result = Resolve-JiraTextFieldPayload -Text '' -IsCloud $true
                $result | Should -BeOfType [string]
                $result | Should -Be ''
            }

            It "returns a whitespace-only string verbatim (does not wrap)" {
                $result = Resolve-JiraTextFieldPayload -Text "   `n  " -IsCloud $true
                $result | Should -BeOfType [string]
            }

            It "returns `$null verbatim" {
                $result = Resolve-JiraTextFieldPayload -Text $null -IsCloud $true
                $result | Should -BeNullOrEmpty
            }

            It "warns when input looks like wiki-markup table syntax" {
                $warnings = $null
                $null = Resolve-JiraTextFieldPayload -Text "||a||b||`n|1|2|" -IsCloud $true -WarningVariable warnings -WarningAction SilentlyContinue
                $warnings | Should -Not -BeNullOrEmpty
                ($warnings | Out-String) | Should -Match 'wiki-markup table'
            }

            It "does not warn for valid Markdown tables" {
                $warnings = $null
                $null = Resolve-JiraTextFieldPayload -Text "| a | b |`n| --- | --- |`n| 1 | 2 |" -IsCloud $true -WarningVariable warnings -WarningAction SilentlyContinue
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
