#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $script:envDiscovery = Initialize-IntegrationEnvironment
        $script:SkipGroupTests = [string]::IsNullOrEmpty($envDiscovery.TestGroup)
    }
}

InModuleScope JiraPS {
    Describe "Groups" -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Describe "Get-JiraGroup" -Skip:$SkipGroupTests {
            Context "Group Retrieval" {
                It "retrieves a group by name" {
                    $group = Get-JiraGroup -GroupName $fixtures.TestGroup

                    $group | Should -Not -BeNullOrEmpty
                }

                It "returns group object with correct type" {
                    $group = Get-JiraGroup -GroupName $fixtures.TestGroup

                    $group.PSObject.TypeNames[0] | Should -Be 'JiraPS.Group'
                }

                It "includes group name" {
                    $group = Get-JiraGroup -GroupName $fixtures.TestGroup

                    $group.Name | Should -Be $fixtures.TestGroup
                }
            }

            Context "Error Handling" {
                It "fails for non-existent group" {
                    { Get-JiraGroup -GroupName 'nonexistent-group-12345' -ErrorAction Stop } |
                        Should -Throw
                }
            }
        }

        Describe "Get-JiraGroupMember" -Skip:$SkipGroupTests {
            Context "Group Members" {
                It "retrieves members of a group" {
                    $members = Get-JiraGroupMember -Group $fixtures.TestGroup

                    $members | Should -BeOfType [PSCustomObject]
                }

                It "returns user objects" {
                    $members = Get-JiraGroupMember -Group $fixtures.TestGroup

                    if ($members) {
                        @($members)[0].PSObject.TypeNames[0] | Should -Be 'JiraPS.User'
                    }
                }
            }
        }
    }
}
