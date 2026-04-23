#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
}

InModuleScope JiraPS {
    Describe "Server Information" -Tag 'Integration', 'Smoke' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Describe "Get-JiraConfigServer" {
            It "returns the configured server URL" {
                $server = Get-JiraConfigServer

                $server | Should -Not -BeNullOrEmpty
                $server | Should -Be $fixtures.CloudUrl
            }
        }

        Describe "Get-JiraServerInformation" {
            BeforeAll {
                $script:serverInfo = Get-JiraServerInformation
            }

            It "retrieves server information" {
                $serverInfo | Should -Not -BeNullOrEmpty
            }

            It "returns the correct type" {
                $serverInfo.PSObject.TypeNames[0] | Should -Be 'JiraPS.ServerInfo'
            }

            It "includes the base URL" {
                $serverInfo.BaseURL | Should -Not -BeNullOrEmpty
            }

            It "includes the version" {
                $serverInfo.Version | Should -Not -BeNullOrEmpty
            }

            It "identifies as Cloud deployment" {
                $serverInfo.DeploymentType | Should -Be 'Cloud'
            }

            It "includes build information" {
                $serverInfo.BuildNumber | Should -Not -BeNullOrEmpty
            }

            It "includes server title" {
                $serverInfo.ServerTitle | Should -Not -BeNullOrEmpty
            }
        }
    }
}
