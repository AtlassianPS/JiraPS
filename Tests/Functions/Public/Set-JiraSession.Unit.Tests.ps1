#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }
BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}
Describe 'Set-JiraSession' -Tag Unit {

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


        It 'selects the same default through the compatibility command' {
            $connection = Connect-Jira -Name contract-first -Uri https://jira.example.com -Anonymous
            $connection | Set-JiraSession | Out-Null
            (Get-JiraConnection -Default).InstanceId | Should -Be $connection.InstanceId
        }

    }
}
