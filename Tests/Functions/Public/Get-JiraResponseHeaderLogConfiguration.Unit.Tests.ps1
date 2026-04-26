#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Get-JiraResponseHeaderLogConfiguration" -Tag 'Unit' {
        BeforeEach {
            $script:JiraResponseHeaderLogConfiguration = $null
        }

        It "returns null when no configuration has been set" {
            Get-JiraResponseHeaderLogConfiguration | Should -BeNullOrEmpty
        }

        It "returns the configuration object set by Set-JiraResponseHeaderLogConfiguration" {
            Set-JiraResponseHeaderLogConfiguration -Include 'X-A*'

            $config = Get-JiraResponseHeaderLogConfiguration

            $config | Should -Not -BeNullOrEmpty
            $config.Mode | Should -Be 'Wildcard'
            Test-JiraResponseHeaderMatch -Configuration $config -Name 'X-AREQUESTID' | Should -BeTrue
        }

        It "returns null after Set-JiraResponseHeaderLogConfiguration -Disable" {
            Set-JiraResponseHeaderLogConfiguration -Include 'X-A*'

            Set-JiraResponseHeaderLogConfiguration -Disable

            Get-JiraResponseHeaderLogConfiguration | Should -BeNullOrEmpty
        }
    }
}
