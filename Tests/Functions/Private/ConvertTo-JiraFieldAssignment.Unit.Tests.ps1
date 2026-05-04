#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraFieldAssignment" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:scopedField = [PSCustomObject]@{
                Id     = 'customfield_10001'
                Name   = 'Scoped Field'
                Schema = [PSCustomObject]@{ type = 'string' }
            }
            $script:fallbackField = [PSCustomObject]@{
                Id     = 'customfield_20001'
                Name   = 'Fallback Field'
                Schema = [PSCustomObject]@{ type = 'string' }
            }
            $script:anotherFallbackField = [PSCustomObject]@{
                Id     = 'customfield_20002'
                Name   = 'Another Fallback Field'
                Schema = [PSCustomObject]@{ type = 'string' }
            }
            $script:richTextField = [PSCustomObject]@{
                Id     = 'description'
                Name   = 'Description'
                Schema = [PSCustomObject]@{ type = 'string'; system = 'description' }
            }
            $script:dupeField1 = [PSCustomObject]@{
                Id     = 'customfield_30001'
                Name   = 'Duplicate'
                Schema = [PSCustomObject]@{ type = 'string' }
            }
            $script:dupeField2 = [PSCustomObject]@{
                Id     = 'customfield_30002'
                Name   = 'Duplicate'
                Schema = [PSCustomObject]@{ type = 'string' }
            }
        }

        BeforeEach {
            Mock Get-JiraField -ModuleName JiraPS {
                @($fallbackField, $anotherFallbackField, $richTextField)
            }

            Mock Test-JiraRichTextField -ModuleName JiraPS { $false }
            Mock Resolve-JiraTextFieldPayload -ModuleName JiraPS { "ADF:$Text" }
        }

        It "resolves scoped fields without fetching the global field list" {
            $result = ConvertTo-JiraFieldAssignment -Fields @{ 'Scoped Field' = 'scoped value' } -ScopedMeta @($scopedField) -IsCloud $false -FallbackFieldFetcher { Get-JiraField }

            $result | Should -HaveCount 1
            $result[0].Id | Should -Be 'customfield_10001'
            $result[0].Value | Should -Be 'scoped value'
            Should -Invoke Get-JiraField -ModuleName JiraPS -Exactly -Times 0
        }

        It "fetches the global field list at most once for multiple unscoped fields" {
            $result = ConvertTo-JiraFieldAssignment -Fields @{
                'Fallback Field'         = 'a'
                'Another Fallback Field' = 'b'
            } -ScopedMeta @() -IsCloud $false -FallbackFieldFetcher { Get-JiraField }

            $result | Should -HaveCount 2
            @($result.Id) | Should -Contain 'customfield_20001'
            @($result.Id) | Should -Contain 'customfield_20002'
            Should -Invoke Get-JiraField -ModuleName JiraPS -Exactly -Times 1
        }

        It "wraps Cloud rich-text string values via Resolve-JiraTextFieldPayload" {
            Mock Get-JiraField -ModuleName JiraPS { @($richTextField) }
            Mock Test-JiraRichTextField -ModuleName JiraPS -ParameterFilter { $Field.Id -eq 'description' } { $true }

            $result = ConvertTo-JiraFieldAssignment -Fields @{ description = 'Hello world' } -ScopedMeta @() -IsCloud $true -FallbackFieldFetcher { Get-JiraField }

            $result | Should -HaveCount 1
            $result[0].Value | Should -Be 'ADF:Hello world'
            Should -Invoke Resolve-JiraTextFieldPayload -ModuleName JiraPS -Exactly -Times 1
        }

        It "leaves non-string values unchanged on Cloud" {
            Mock Get-JiraField -ModuleName JiraPS { @($richTextField) }
            Mock Test-JiraRichTextField -ModuleName JiraPS -ParameterFilter { $Field.Id -eq 'description' } { $true }

            $result = ConvertTo-JiraFieldAssignment -Fields @{ description = @{ text = 'already structured' } } -ScopedMeta @() -IsCloud $true -FallbackFieldFetcher { Get-JiraField }

            $result[0].Value.text | Should -Be 'already structured'
            Should -Invoke Resolve-JiraTextFieldPayload -ModuleName JiraPS -Exactly -Times 0
        }

        It "preserves ambiguity failures from Resolve-JiraField" {
            Mock Get-JiraField -ModuleName JiraPS { @($dupeField1, $dupeField2) }

            {
                ConvertTo-JiraFieldAssignment -Fields @{ Duplicate = 'value' } -ScopedMeta @() -IsCloud $false -FallbackFieldFetcher { Get-JiraField } -ErrorAction Stop
            } | Should -Throw -ExceptionType ([System.ArgumentException])
        }

        It "preserves not-found failures from Resolve-JiraField" {
            {
                ConvertTo-JiraFieldAssignment -Fields @{ MissingField = 'value' } -ScopedMeta @() -IsCloud $false -FallbackFieldFetcher { @() } -ErrorAction Stop
            } | Should -Throw -ExceptionType ([System.ArgumentException])
        }

        It "does not fetch fallback fields when the fetcher is omitted and all keys resolve from scoped metadata" {
            $result = ConvertTo-JiraFieldAssignment -Fields @{ 'Scoped Field' = 'scoped value' } -ScopedMeta @($scopedField) -IsCloud $false

            $result | Should -HaveCount 1
            $result[0].Id | Should -Be 'customfield_10001'
            Should -Invoke Get-JiraField -ModuleName JiraPS -Exactly -Times 0
        }
    }
}
