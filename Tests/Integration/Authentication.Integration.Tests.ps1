#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Integration tests require plaintext credential conversion for API tokens')]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
}

InModuleScope JiraPS {
    Describe "Authentication" -Tag 'Integration', 'Smoke', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:secureToken = ConvertTo-SecureString -String $env.Password -AsPlainText -Force
        }

        AfterEach {
            Get-JiraConnection | Disconnect-Jira -ErrorAction SilentlyContinue
        }

        Context "Connect-Jira" {
            It 'creates an active connection with a validated identity using an API token' {
                $session = Connect-Jira -Name 'authentication-integration' -Uri $env.CloudUrl -ApiToken $secureToken -EmailAddress $env.Username -ErrorAction Stop

                $session | Should -BeOfType ([AtlassianPS.Connection])
                $session.State | Should -Be 'Active'
                $session.Username | Should -Not -BeNullOrEmpty
                (Get-JiraUser -Connection $session -ErrorAction Stop).AccountId | Should -Be $session.Username
            }

            It "fails with invalid API token" {
                $badToken = ConvertTo-SecureString -String "invalid-token" -AsPlainText -Force

                { Connect-Jira -Name 'authentication-integration' -Uri $env.CloudUrl -ApiToken $badToken -EmailAddress $env.Username -ErrorAction Stop } |
                    Should -Throw
            }

            It "fails with invalid email address" {
                {
                    Connect-Jira -Name 'authentication-integration' -Uri $env.CloudUrl -ApiToken $secureToken -EmailAddress "invalid@example.com" -ErrorAction Stop
                } |
                    Should -Throw
            }
        }

        Context "Get-JiraConnection" {

            It "returns the current session after authentication" {
                Connect-Jira -Name 'authentication-integration' -Uri $env.CloudUrl -ApiToken $secureToken -EmailAddress $env.Username

                $session = Get-JiraConnection

                $session | Should -Not -BeNullOrEmpty
                $session.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.Connection'
            }
        }

        Context "Disconnect-Jira" {
            It "removes an existing session" {
                Connect-Jira -Name 'authentication-integration' -Uri $env.CloudUrl -ApiToken $secureToken -EmailAddress $env.Username

                Get-JiraConnection | Should -Not -BeNullOrEmpty

                Get-JiraConnection | Disconnect-Jira

                Get-JiraConnection | Should -BeNullOrEmpty
            }

        }
    }
}
