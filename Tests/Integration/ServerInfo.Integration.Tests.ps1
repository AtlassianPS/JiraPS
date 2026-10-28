#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
}

InModuleScope JiraPS {
    Describe "Server Information" -Tag 'Integration', 'Smoke', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
        }

        AfterAll {
            Disconnect-Jira -ErrorAction SilentlyContinue
        }

        Describe "Connection endpoint" {
            It "returns the active connection API endpoint" {
                $server = (Get-JiraConnection -Default).BaseUri.AbsoluteUri.TrimEnd('/')

                $server | Should -Not -BeNullOrEmpty
                $server | Should -Be $session.BaseUri.AbsoluteUri.TrimEnd('/')
            }
        }

        Describe "Get-JiraServerInformation" {
            BeforeAll {
                $script:serverInfo = Get-JiraServerInformation
            }

            It 'returns typed Jira metadata with the expected deployment' {
                $serverInfo | Should -BeOfType ([AtlassianPS.JiraPS.ServerInfo])
                $serverInfo.BaseURL | Should -Not -BeNullOrEmpty
                $serverInfo.Version | Should -Not -BeNullOrEmpty
                $expected = if ($fixtures.IsCloud) { 'Cloud' } else { 'Server' }
                $serverInfo.DeploymentType | Should -Be $expected
                $serverInfo.BuildNumber | Should -Not -BeNullOrEmpty
                $serverInfo.ServerTitle | Should -Not -BeNullOrEmpty
            }
        }
    }
}
