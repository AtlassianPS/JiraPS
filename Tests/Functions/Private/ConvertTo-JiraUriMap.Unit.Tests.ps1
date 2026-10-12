#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraUriMap" -Tag 'Unit' {
        It 'preserves map keys for JSON, hashtable and typed dictionary inputs' {
            $json = ConvertFrom-Json -InputObject @'
{
    "16x16": "https://jira.example/avatar.png"
}
'@
            $hashtable = @{ '16x16' = 'https://jira.example/avatar.png' }
            $dictionary = ConvertTo-JiraUriMap -InputObject $json
            foreach ($inputMap in @($json, $hashtable, $dictionary)) {
                $result = ConvertTo-JiraUriMap -InputObject $inputMap
                $result.GetType() | Should -Be ([System.Collections.Generic.Dictionary[string, uri]])
                $result.Count | Should -Be 1
                $result['16x16'] | Should -Be ([uri]'https://jira.example/avatar.png')
            }
        }

        It 'distinguishes an absent map from an empty map and omits null URLs' {
            ConvertTo-JiraUriMap -InputObject $null | Should -BeNullOrEmpty
            $empty = ConvertTo-JiraUriMap -InputObject ([PSCustomObject]@{})
            $empty.GetType() | Should -Be ([System.Collections.Generic.Dictionary[string, uri]])
            $empty.Count | Should -Be 0
            (ConvertTo-JiraUriMap -InputObject @{ optional = $null }).Count | Should -Be 0
        }
    }
}
