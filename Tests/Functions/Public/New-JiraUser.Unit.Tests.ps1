#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'New-JiraUser deployment contract' -Tag Unit {
        BeforeEach {
            Mock Test-JiraCloudServer { $false }
            Mock Invoke-JiraRequest {
                [PSCustomObject]@{ name = $Body.name; emailAddress = $Body.emailAddress; accountId = 'created-user' }
            }
        }

        It 'creates a Data Center user with a username and default display name' {
            $result = New-JiraUser -EmailAddress 'me@example.com' -UserName 'me'
            $result.Name | Should -Be 'me'
            Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter {
                $Uri -eq '/rest/api/2/user' -and $Body.name -eq 'me' -and $Body.displayName -eq 'me' -and -not $Body.ContainsKey('notification')
            }
        }

        It 'requires a username on Data Center' {
            { New-JiraUser -EmailAddress 'me@example.com' } | Should -Throw '*requires UserName*'
            Should -Invoke Invoke-JiraRequest -Exactly 0
        }

        It 'creates a Cloud user with explicit products and without Data Center fields' {
            Mock Test-JiraCloudServer { $true }
            New-JiraUser -EmailAddress 'me@example.com' -Products jira-software
            Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter {
                $Uri -eq '/rest/api/3/user' -and $Body.products[0] -eq 'jira-software' -and
                -not $Body.ContainsKey('name') -and -not $Body.ContainsKey('displayName') -and -not $Body.ContainsKey('notification')
            }
        }

        It 'preserves an explicitly empty Cloud product list' {
            Mock Test-JiraCloudServer { $true }
            New-JiraUser -EmailAddress 'me@example.com' -Products @()
            Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter { $Body.ContainsKey('products') -and $Body.products.Count -eq 0 }
        }

        It 'requires explicit Cloud products and rejects Data Center fields' {
            Mock Test-JiraCloudServer { $true }
            { New-JiraUser -EmailAddress 'me@example.com' } | Should -Throw '*requires an explicit Products*'
            { New-JiraUser -EmailAddress 'me@example.com' -Products @() -UserName 'me' } | Should -Throw '*does not accept UserName*'
            Should -Invoke Invoke-JiraRequest -Exactly 0
        }

        It 'does not create users under WhatIf' {
            New-JiraUser -EmailAddress 'me@example.com' -UserName 'me' -WhatIf
            Should -Invoke Invoke-JiraRequest -Exactly 0
        }
    }
}
