#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Connect-Jira' -Tag Unit {
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

        It 'validates the product and identity before registering and preserves the default' {
            $first = Connect-Jira -Name contract-first -Uri https://jira.example.com -PersonalAccessToken first
            $second = Connect-Jira -Name contract-second -Uri https://jira.example.com -PersonalAccessToken second -Default

            $first | Should -BeOfType ([AtlassianPS.Connection])
            $first.Username | Should -Be 'validated-user'
            (Get-JiraConnection -Default).InstanceId | Should -Be $second.InstanceId
            $first.GetAuthorizationHeader() | Should -Be 'Bearer first'
            $second.GetAuthorizationHeader() | Should -Be 'Bearer second'
        }

        It 'uses only the profile endpoint and explicitly supplied authentication' {
            Add-AtlassianServerConfiguration -Name contract-saved -Type Jira -Uri https://jira.example.com/jira
            $profile = Get-AtlassianServerConfiguration -Name contract-saved
            $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate]::new()

            try {
                $profile.Headers = @{ Authorization = 'stored-header' }
                $profile.Certificate = $certificate
                $profile.Session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
                $profile.Session.Headers['Authorization'] = 'stored-session'

                $connection = Connect-Jira -Name contract-profile -Profile contract-saved -PersonalAccessToken supplied-token

                $connection.BaseUri.AbsoluteUri | Should -Be 'https://jira.example.com/jira'
                $connection.GetAuthorizationHeader() | Should -Be 'Bearer supplied-token'
                $connection.Username | Should -Be 'validated-user'
            }
            finally {
                Remove-AtlassianServerConfiguration -Name contract-saved -Confirm:$false
                $certificate.Dispose()
            }
        }

        It 'does not register or change defaults after anonymous metadata with failed identity validation' {
            Mock Invoke-JiraMethod {
                [PSCustomObject]@{
                    version        = '11.0'
                    deploymentType = 'Server'
                }
            }
            $before = (Get-JiraConnection -Default).InstanceId

            { Connect-Jira -Name contract-invalid -Uri https://jira.example.com -PersonalAccessToken sentinel -Default } | Should -Throw '*identity*'
            Get-JiraConnection -Name contract-invalid | Should -BeNullOrEmpty
            (Get-JiraConnection -Default).InstanceId | Should -Be $before
        }

        It 'preserves metadata transport failures without registering a connection' {
            Mock Invoke-JiraMethod { Write-Error 'Metadata transport failed.' }
            $before = (Get-JiraConnection -Default).InstanceId

            { Connect-Jira -Name contract-transport -Uri https://jira.example.com -Anonymous } | Should -Throw '*Metadata transport failed*'

            Get-JiraConnection -Name contract-transport | Should -BeNullOrEmpty
            (Get-JiraConnection -Default).InstanceId | Should -Be $before
        }

        It 'rejects invalid authentication before HTTP' {
            { Connect-Jira -Name contract-invalid -Uri https://jira.example.com -PersonalAccessToken '' } | Should -Throw
            { Connect-Jira -Name contract-invalid -Uri https://jira.example.com -ApiToken token } | Should -Throw
            { Connect-Jira -Name contract-invalid -Uri https://jira.example.com -Anonymous -PersonalAccessToken token } | Should -Throw
            Should -Invoke Invoke-JiraMethod -Times 0 -Exactly
        }

        It 'rejects wrong-product metadata before registration' {
            Mock Invoke-JiraMethod { [PSCustomObject]@{ product = 'Confluence' } }

            { Connect-Jira -Name contract-invalid -Uri https://jira.example.com -Anonymous } | Should -Throw '*Jira server information*'
        }
    }
}
