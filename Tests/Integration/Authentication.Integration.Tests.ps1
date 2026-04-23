#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Integration tests require plaintext credential conversion for API tokens')]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
}

InModuleScope JiraPS {
    Describe "Authentication" -Tag 'Integration', 'Smoke' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Context "Set-JiraConfigServer" {
            It "configures the Jira server URL" {
                { Set-JiraConfigServer -Server $env.CloudUrl } | Should -Not -Throw
            }

            It "stores the server URL for subsequent calls" {
                Set-JiraConfigServer -Server $env.CloudUrl

                $server = Get-JiraConfigServer
                $server | Should -Be $env.CloudUrl
            }
        }

        Context "New-JiraSession" {
            BeforeAll {
                Set-JiraConfigServer -Server $env.CloudUrl
                $script:secureToken = ConvertTo-SecureString -String $env.Password -AsPlainText -Force
            }

            AfterEach {
                Remove-JiraSession -ErrorAction SilentlyContinue
            }

            It "creates a session with valid API token" {
                $session = New-JiraSession -ApiToken $secureToken -EmailAddress $env.Username

                $session | Should -Not -BeNullOrEmpty
            }

            It "returns a session object with correct type" {
                $session = New-JiraSession -ApiToken $secureToken -EmailAddress $env.Username

                $session.PSObject.TypeNames[0] | Should -Be 'JiraPS.Session'
            }

            It "enables subsequent API calls without explicit credentials" {
                New-JiraSession -ApiToken $secureToken -EmailAddress $env.Username

                $serverInfo = Get-JiraServerInformation
                $serverInfo | Should -Not -BeNullOrEmpty
            }

            It "fails with invalid API token" {
                $badToken = ConvertTo-SecureString -String "invalid-token" -AsPlainText -Force

                { New-JiraSession -ApiToken $badToken -EmailAddress $env.Username -ErrorAction Stop } |
                    Should -Throw
            }

            It "fails with invalid email address" {
                { New-JiraSession -ApiToken $secureToken -EmailAddress "invalid@example.com" -ErrorAction Stop } |
                    Should -Throw
            }
        }

        Context "Get-JiraSession" {
            BeforeAll {
                Set-JiraConfigServer -Server $env.CloudUrl

                $script:secureToken = ConvertTo-SecureString -String $env.Password -AsPlainText -Force
            }

            It "returns null when no session exists" {
                Remove-JiraSession -ErrorAction SilentlyContinue

                $session = Get-JiraSession
                $session | Should -BeNullOrEmpty
            }

            It "returns the current session after authentication" {
                New-JiraSession -ApiToken $secureToken -EmailAddress $env.Username

                $session = Get-JiraSession
                $session | Should -Not -BeNullOrEmpty
                $session.PSObject.TypeNames[0] | Should -Be 'JiraPS.Session'
            }
        }

        Context "Remove-JiraSession" {
            BeforeAll {
                Set-JiraConfigServer -Server $env.CloudUrl

                $script:secureToken = ConvertTo-SecureString -String $env.Password -AsPlainText -Force
            }

            It "removes an existing session" {
                New-JiraSession -ApiToken $secureToken -EmailAddress $env.Username
                Get-JiraSession | Should -Not -BeNullOrEmpty

                Remove-JiraSession

                Get-JiraSession | Should -BeNullOrEmpty
            }

            It "succeeds even when no session exists" {
                Remove-JiraSession -ErrorAction SilentlyContinue

                { Remove-JiraSession } | Should -Not -Throw
            }
        }
    }
}
