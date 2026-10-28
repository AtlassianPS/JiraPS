#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $script:envDiscovery = Initialize-IntegrationEnvironment
        $script:IsCloud = $envDiscovery.IsCloud
        if ([string]::IsNullOrEmpty($envDiscovery.TestGroup)) {
            throw "Integration test fixture 'TestGroup' is required for Groups.Integration.Tests.ps1. Configure JIRA_TEST_GROUP for Cloud runs and ensure Wait-JiraServer.ps1 exports it for Server runs."
        }
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
            Disconnect-Jira -ErrorAction SilentlyContinue
        }

        Describe "Get-JiraGroup" {
            Context "Group Retrieval" {
                It "retrieves a group by name" {
                    $group = Get-JiraGroup -GroupName $fixtures.TestGroup

                    $group | Should -Not -BeNullOrEmpty
                }

                It "returns group object with correct type" {
                    $group = Get-JiraGroup -GroupName $fixtures.TestGroup

                    $group.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Group'
                }

                It "includes group name" {
                    $group = Get-JiraGroup -GroupName $fixtures.TestGroup

                    $group.Name | Should -Be $fixtures.TestGroup
                }

                It "exposes Id on Jira Cloud" -Skip:(-not $IsCloud) {
                    $group = Get-JiraGroup -GroupName $fixtures.TestGroup

                    $group.Id | Should -Not -BeNullOrEmpty
                }
            }

            Context "Error Handling" {
                It "fails for non-existent group" {
                    { Get-JiraGroup -GroupName 'nonexistent-group-12345' -ErrorAction Stop } |
                        Should -Throw
                }
            }
        }

        Describe "Get-JiraGroupMember" {
            Context "Group Members" {
                It 'retrieves the same typed members by group name and resolved group' {
                    $members = @(Get-JiraGroupMember -Group $fixtures.TestGroup -ErrorAction Stop)
                    $group = Get-JiraGroup -GroupName $fixtures.TestGroup -ErrorAction Stop
                    $resolvedMembers = @(Get-JiraGroupMember -Group $group -ErrorAction Stop)
                    $identity = $fixtures.UserIdProperty

                    $members | Should -Not -BeNullOrEmpty
                    foreach ($member in $resolvedMembers) { $member | Should -BeOfType ([AtlassianPS.JiraPS.User]) }
                    @($resolvedMembers.$identity | Sort-Object) | Should -Be @($members.$identity | Sort-Object)
                }
            }
        }
    }
}
