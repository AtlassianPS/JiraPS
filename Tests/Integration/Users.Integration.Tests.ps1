#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $script:envDiscovery = Initialize-IntegrationEnvironment
        $script:SkipUserTests = [string]::IsNullOrEmpty($envDiscovery.TestUser)
    }
}

InModuleScope JiraPS {
    Describe "Users" -Tag 'Integration' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Describe "Get-JiraUser" {
            Context "User Retrieval" -Skip:$SkipUserTests {
                It "retrieves a user by account ID" {
                    $user = Get-JiraUser -AccountId $fixtures.TestUser

                    $user | Should -Not -BeNullOrEmpty
                }

                It "returns user object with correct type" {
                    $user = Get-JiraUser -AccountId $fixtures.TestUser

                    $user.PSObject.TypeNames[0] | Should -Be 'JiraPS.User'
                }

                It "includes display name" {
                    $user = Get-JiraUser -AccountId $fixtures.TestUser

                    $user.DisplayName | Should -Not -BeNullOrEmpty
                }

                It "includes account ID" {
                    $user = Get-JiraUser -AccountId $fixtures.TestUser

                    $user.AccountId | Should -Be $fixtures.TestUser
                }
            }

            Context "Current User" {
                It "retrieves the current authenticated user via session" {
                    $session = Get-JiraSession

                    $session | Should -Not -BeNullOrEmpty
                    $session.WebSession | Should -Not -BeNullOrEmpty -Because "session should have a valid WebSession"
                }
            }

            Context "Error Handling" {
                It "fails for non-existent account ID" {
                    { Get-JiraUser -AccountId 'nonexistent-account-id-12345' -ErrorAction Stop } |
                        Should -Throw
                }
            }
        }
    }
}
