#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }
BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}
InModuleScope JiraPS {
    Describe 'Get-JiraConfigServer' -Tag Unit {

        It 'prefers the active API endpoint over legacy migration state' {
            $script:JiraServerUrl = [Uri]'https://legacy.example.com'
            Get-JiraConfigServer | Should -Be (Get-JiraConnection -Default).BaseUri.AbsoluteUri.TrimEnd('/')
        }

    }
}
