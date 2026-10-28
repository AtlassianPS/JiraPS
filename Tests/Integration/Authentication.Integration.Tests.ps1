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
        }

        AfterAll {
            Get-JiraConnection | Disconnect-Jira -ErrorAction SilentlyContinue
        }

        Context "Connect-Jira" {
            BeforeAll {
                $script:secureToken = ConvertTo-SecureString -String $env.Password -AsPlainText -Force
            }

            AfterEach {
                Get-JiraConnection | Disconnect-Jira -ErrorAction SilentlyContinue
            }

            It "creates a session with valid API token" {
                $session = Connect-Jira -Name 'authentication-integration' -Uri $env.CloudUrl -ApiToken $secureToken -EmailAddress $env.Username

                $session | Should -Not -BeNullOrEmpty
            }

            It "returns a session object with correct type" {
                $session = Connect-Jira -Name 'authentication-integration' -Uri $env.CloudUrl -ApiToken $secureToken -EmailAddress $env.Username

                $session.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.Connection'
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
            BeforeAll {

                $script:secureToken = ConvertTo-SecureString -String $env.Password -AsPlainText -Force
            }

            It "returns null when no session exists" {
                Get-JiraConnection | Disconnect-Jira -ErrorAction SilentlyContinue

                $session = Get-JiraConnection

                $session | Should -BeNullOrEmpty
            }

            It "returns the current session after authentication" {
                Connect-Jira -Name 'authentication-integration' -Uri $env.CloudUrl -ApiToken $secureToken -EmailAddress $env.Username

                $session = Get-JiraConnection

                $session | Should -Not -BeNullOrEmpty
                $session.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.Connection'
            }
        }

        Context "Disconnect-Jira" {
            BeforeAll {

                $script:secureToken = ConvertTo-SecureString -String $env.Password -AsPlainText -Force
            }

            It "removes an existing session" {
                Connect-Jira -Name 'authentication-integration' -Uri $env.CloudUrl -ApiToken $secureToken -EmailAddress $env.Username

                Get-JiraConnection | Should -Not -BeNullOrEmpty

                Get-JiraConnection | Disconnect-Jira

                Get-JiraConnection | Should -BeNullOrEmpty
            }

            It "succeeds even when no session exists" {
                Get-JiraConnection | Disconnect-Jira -ErrorAction SilentlyContinue

                { Disconnect-Jira } | Should -Not -Throw
            }
        }
    }
}
