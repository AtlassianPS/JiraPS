#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '6.2.0'; MaximumVersion = '6.999' }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Remove-JiraFilterPermission' -Tag Unit {
        BeforeEach {
            $script:filter = [AtlassianPS.JiraPS.Filter]@{
                Id                = '12345'
                Name              = 'Review filter'
                RestUrl           = 'https://jira.example.com/rest/api/2/filter/12345'
                FilterPermissions = @([AtlassianPS.JiraPS.FilterPermission]@{ Id = 999 })
            }
            Mock Get-JiraFilterOperation { $script:filter }
            Mock Invoke-JiraRequest {
                if ($Method -eq 'Get') {
                    [PSCustomObject]@{ id = 0; type = 'global' }
                    [PSCustomObject]@{ id = 2222; type = 'group' }
                }
            }
        }

        It 'removes explicit permissions without fetching all permissions' {
            Remove-JiraFilterPermission -Filter $filter -Permission 0, 4294967296 -Confirm:$false
            Should -Invoke Invoke-JiraRequest -Exactly 0 -ParameterFilter { $Method -eq 'Get' }
            Should -Invoke Invoke-JiraRequest -Exactly 2 -ParameterFilter {
                $Method -eq 'Delete' -and $Uri -match '/permission/(0|4294967296)$'
            }
        }

        It 'fetches current permissions for All instead of using embedded stale permissions' {
            $filter | Remove-JiraFilterPermission -All -Confirm:$false
            Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter { $Method -eq 'Get' -and $Uri -like '*/filter/12345/permission' }
            Should -Invoke Invoke-JiraRequest -Exactly 2 -ParameterFilter { $Method -eq 'Delete' -and $Uri -match '/permission/(0|2222)$' }
            Should -Invoke Invoke-JiraRequest -Exactly 0 -ParameterFilter { $Method -eq 'Delete' -and $Uri -like '*/permission/999' }
        }

        It 'does not remove permissions under WhatIf' {
            Remove-JiraFilterPermission -Filter $filter -All -WhatIf
            Should -Invoke Invoke-JiraRequest -Exactly 0 -ParameterFilter { $Method -eq 'Delete' }
        }

        It 'requires explicit permission selection or All' {
            { Remove-JiraFilterPermission -Filter $filter } | Should -Throw '*Permission*'
            { Remove-JiraFilterPermission -Filter $filter -All:$false } | Should -Throw '*Supply -All*'
            Should -Invoke Invoke-JiraRequest -Exactly 0
        }

        It 'rejects mutually exclusive All and Permission' {
            { Remove-JiraFilterPermission -Filter $filter -All -Permission 1 } | Should -Throw
            Should -Invoke Invoke-JiraRequest -Exactly 0
        }

        It 'validates every returned permission before any deletion' {
            Mock Invoke-JiraRequest {
                [PSCustomObject]@{ id = 2222; type = 'group' }
                [PSCustomObject]@{ type = 'global' }
            } -ParameterFilter { $Method -eq 'Get' }
            { Remove-JiraFilterPermission -Filter $filter -All -Confirm:$false } |
                Should -Throw '*non-negative numeric permission IDs*'
            Should -Invoke Invoke-JiraRequest -Exactly 0 -ParameterFilter { $Method -eq 'Delete' }
        }

        It 'fails actionably when All finds no permissions' {
            Mock Invoke-JiraRequest { @() } -ParameterFilter { $Method -eq 'Get' }
            { Remove-JiraFilterPermission -Filter $filter -All } | Should -Throw '*no permissions to remove*'
            Should -Invoke Invoke-JiraRequest -Exactly 0 -ParameterFilter { $Method -eq 'Delete' }
        }
    }
}
