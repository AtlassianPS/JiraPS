#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Disconnect-Jira' -Tag Unit {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:moduleToTest = Initialize-TestEnvironment
        }

        BeforeEach {
            $script:previousDefault = Get-JiraConnection -Default
            Mock Invoke-JiraMethod {
                if ($Uri -eq '/rest/api/2/serverInfo') {
                    return [PSCustomObject]@{
                        version        = '11.0'
                        deploymentType = 'Server'
                    }
                }
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

        It 'disconnects only the current Jira default without promoting another' {
            $first = Connect-Jira -Name contract-first -Uri https://jira.example.com -Anonymous
            $second = Connect-Jira -Name contract-second -Uri https://jira.example.com -Anonymous -Default
            Disconnect-Jira

            $first.State | Should -Be 'Active'
            $second.State | Should -Be 'Disconnected'
            Get-JiraConnection -Default | Should -BeNullOrEmpty
        }

        It 'rejects an explicitly false All switch without disconnecting anything' {
            $first = Connect-Jira -Name contract-first -Uri https://jira.example.com -Anonymous

            { Disconnect-Jira -All:$false } | Should -Throw
            $first.State | Should -Be 'Active'
        }

        It 'honors WhatIf without invalidating the handle' {
            $first = Connect-Jira -Name contract-first -Uri https://jira.example.com -Anonymous
            $first | Disconnect-Jira -WhatIf

            $first.State | Should -Be 'Active'
        }
    }
}
