#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    # Replace the command, endpoint, model and fixture with the behavior under test.
    Describe 'Your-Command' -Tag Unit {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            Mock Invoke-JiraRequest { throw "Unexpected request: $Method $Uri" }
            Mock Invoke-JiraRequest {
                [PSCustomObject]@{ id = '12345'; name = 'Created item' }
            } -ParameterFilter { $Method -eq 'Post' -and $Uri -eq '/rest/api/2/resource' }
        }

        It 'creates the requested resource and returns its typed result' {
            $result = Your-Command -Name 'Created item' -Confirm:$false

            Should -Invoke Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter {
                $Method -eq 'Post' -and $Uri -eq '/rest/api/2/resource' -and
                ($Body | ConvertFrom-Json).name -eq 'Created item'
            }
            $result | Should -BeOfType ([AtlassianPS.JiraPS.Filter])
            $result.Id | Should -Be '12345'
            $result.Name | Should -Be 'Created item'
        }

        It 'rejects invalid input before contacting Jira' {
            { Your-Command -Name '' -Confirm:$false } | Should -Throw '*Name*'
            Should -Invoke Invoke-JiraRequest -Exactly -Times 0
        }

        It 'makes no request under WhatIf' {
            $result = Your-Command -Name 'Created item' -WhatIf

            Should -Invoke Invoke-JiraRequest -Exactly -Times 0
            $result | Should -BeNullOrEmpty
        }
    }
}
