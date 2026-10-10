#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'ConvertTo-JiraFieldSchema' -Tag Unit {
        It 'retains extensible configuration when raw and typed schemas are converted' {
            $wire = ConvertFrom-Json '{"type":"array","customId":10000,"configuration":{"plugin":{"flags":[true,false]}}}'
            $typed = ConvertTo-JiraFieldSchema $wire
            $hashtable = @{ type = 'array'; customId = 10000; configuration = @{ plugin = @{ flags = @($true, $false) } } }
            foreach ($schema in @($wire, $typed, $hashtable)) {
                $result = ConvertTo-JiraFieldSchema $schema
                $result.GetType() | Should -Be ([AtlassianPS.JiraPS.FieldSchema])
                $result.CustomId | Should -Be 10000
                $result.Configuration.Count | Should -Be 1
                $result.Configuration['plugin'].flags | Should -Be @($true, $false)
            }
        }

        It 'keeps an absent schema null and a present empty configuration typed' {
            ConvertTo-JiraFieldSchema $null | Should -BeNullOrEmpty
            $result = ConvertTo-JiraFieldSchema (ConvertFrom-Json '{"configuration":{}}')
            $result.Configuration.GetType() | Should -Be ([System.Collections.Generic.Dictionary[string, object]])
            $result.Configuration.Count | Should -Be 0
        }
    }
}
