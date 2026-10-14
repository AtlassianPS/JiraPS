#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }
BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}
Describe 'New-JiraSession' -Tag Unit {

    BeforeAll {
        . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        $script:moduleToTest = Initialize-TestEnvironment
    }
    InModuleScope JiraPS {
        BeforeEach {
            $script:previousDefault = Get-JiraConnection -Default
            Mock Invoke-JiraMethod {
                if ($Uri -eq '/rest/api/2/serverInfo') { return [PSCustomObject]@{ version = '11.0'; deploymentType = 'Server' } }
                if ($Uri -eq '/rest/api/2/myself') { return [PSCustomObject]@{ name = 'validated-user' } }
                throw 'Unexpected validation request.'
            }
        }
        AfterEach {
            Get-JiraConnection | Where-Object Name -Like 'contract-*' | Disconnect-Jira
            if ($script:previousDefault -and $script:previousDefault.State -eq 'Active') {
                $script:previousDefault | Select-JiraConnection | Out-Null
            }
        }


        It 'uses unique generated names, the configured endpoint and the shared type' {
            $first = New-JiraSession -PersonalAccessToken first
            $second = New-JiraSession -PersonalAccessToken second
            try {
                $first | Should -BeOfType ([AtlassianPS.Connection])
                $first.Name | Should -Not -Be $second.Name
                $first.BaseUri | Should -Be $previousDefault.BaseUri
                (Get-JiraConnection -Default).InstanceId | Should -Be $previousDefault.InstanceId
            }
            finally { @($first, $second) | Disconnect-Jira }
        }
        It 'rejects injected legacy headers before HTTP' {
            { New-JiraSession -Headers @{ Authorization = 'secret' } } | Should -Throw '*authentication*'
            Should -Invoke Invoke-JiraMethod -Times 0 -Exactly
        }

    }
}
