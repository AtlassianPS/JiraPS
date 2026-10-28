#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $script:envDiscovery = Initialize-IntegrationEnvironment
        $script:SkipUserTests = [string]::IsNullOrEmpty($envDiscovery.TestUser)
    }
}

InModuleScope JiraPS {
    Describe "Users" -Tag 'Integration', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
        }

        AfterAll {
            Disconnect-Jira -ErrorAction SilentlyContinue
        }

        Describe "Get-JiraUser" {
            Context "User Retrieval" -Skip:$SkipUserTests {
                It 'retrieves the requested typed Cloud user with a display name' {
                    $user = Get-JiraUser -User $fixtures.TestUser -ErrorAction Stop

                    $user | Should -BeOfType ([AtlassianPS.JiraPS.User])
                    $user.DisplayName | Should -Not -BeNullOrEmpty
                    $user.AccountId | Should -Be $fixtures.TestUser
                }
            }

            Context "Current User" {
                It "retrieves the current authenticated user via session" {
                    $connection = Get-JiraConnection -Default

                    $connection | Should -BeOfType [AtlassianPS.Connection]
                    $connection.State | Should -Be 'Active'
                    $connection.InstanceId | Should -Be $session.InstanceId

                    $user = Get-JiraUser -ErrorAction Stop
                    $identityProperty = $env.UserIdProperty
                    $user.$identityProperty | Should -Not -BeNullOrEmpty
                    $user.$identityProperty | Should -Be $connection.Username
                }
            }

            Context "Error Handling" {
                It "fails for non-existent account ID" {
                    { Get-JiraUser -User 'nonexistent-account-id-12345' -ErrorAction Stop } |
                        Should -Throw
                }
            }
        }
    }
}
