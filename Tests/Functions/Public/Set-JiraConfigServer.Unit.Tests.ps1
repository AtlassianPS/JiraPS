#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Set-JiraConfigServer' -Tag Unit {

        It 'persists a non-secret shared profile without touching the old server_config file' {
            Mock Save-Configuration {} -ModuleName AtlassianPS.Configuration
            $sentinel = Join-Path $TestDrive server_config
            Set-Content -LiteralPath $sentinel -Value saved-sentinel
            $script:serverConfig = $sentinel
            Set-JiraConfigServer -Server https://legacy.example.com
            Get-Content -LiteralPath $sentinel | Should -Be 'saved-sentinel'
            (AtlassianPS.Configuration\Get-AtlassianServerConfiguration -Name JiraPS.LegacyEndpoint).Uri.Host | Should -Be 'legacy.example.com'
        }

        It 'rejects a relative endpoint' {
            { Set-JiraConfigServer -Server jira.example.com } | Should -Throw '*absolute*'
        }
    }
}
