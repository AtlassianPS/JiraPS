#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
}

InModuleScope JiraPS {
    Describe "Projects" -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Describe "Get-JiraProject" {
            Context "Listing Projects" {
                It "retrieves all accessible projects" {
                    $projects = Get-JiraProject

                    $projects | Should -Not -BeNullOrEmpty
                }

                It "returns project objects with correct type" {
                    $projects = Get-JiraProject

                    @($projects)[0].PSObject.TypeNames[0] | Should -Be 'JiraPS.Project'
                }
            }

            Context "Specific Project" {
                It "retrieves a project by key" {
                    $project = Get-JiraProject -Project $fixtures.TestProject

                    $project | Should -Not -BeNullOrEmpty
                    $project.Key | Should -Be $fixtures.TestProject
                }

                It "includes project name" {
                    $project = Get-JiraProject -Project $fixtures.TestProject

                    $project.Name | Should -Not -BeNullOrEmpty
                }

                It "includes project ID" {
                    $project = Get-JiraProject -Project $fixtures.TestProject

                    $project.Id | Should -Not -BeNullOrEmpty
                }
            }

            Context "Error Handling" {
                It "fails for non-existent project" {
                    { Get-JiraProject -Project 'NONEXISTENT' -ErrorAction Stop } |
                        Should -Throw
                }
            }
        }

        Describe "Get-JiraComponent" {
            Context "Project Components" {
                BeforeAll {
                    $script:components = Get-JiraComponent -Project $fixtures.TestProject -ErrorAction SilentlyContinue
                }

                It "retrieves components for a project" {
                    # The auto-provisioned `TEST` project on the Server CI track ships
                    # without any components (none of the AMPS standalone project templates
                    # registers them by default), so `Get-JiraComponent` legitimately
                    # returns `$null`. Assert the call succeeds and only type-check when
                    # data is present; the dedicated typed-shape assertion lives in the
                    # next `It` block.
                    { Get-JiraComponent -Project $fixtures.TestProject } | Should -Not -Throw

                    if ($components) {
                        @($components)[0] | Should -BeOfType [PSCustomObject]
                    }
                }

                It "returns component objects with correct type" {
                    if (-not $components) {
                        Set-ItResult -Skipped -Because "No components exist in test project"
                        return
                    }
                    @($components)[0].PSObject.TypeNames[0] | Should -Be 'JiraPS.Component'
                }
            }
        }
    }
}
