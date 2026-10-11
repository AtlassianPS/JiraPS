#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
    $script:Skip = Skip-IntegrationTest
}

InModuleScope JiraPS {
    Describe 'Status name encoding' -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
            $script:environment = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $environment
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        It 'retrieves a status whose name contains spaces' {
            $allStatuses = @(Get-JiraStatus -ErrorAction Stop)
            $target = $allStatuses | Where-Object { $_.Name -match '\s' } | Select-Object -First 1
            $target | Should -Not -BeNullOrEmpty -Because 'the integration fixture must contain a status name with spaces'

            $statusByName = @(Get-JiraStatus -Status $target.Name -ErrorAction Stop)

            $statusByName | Should -HaveCount 1
            $statusByName[0].Name | Should -Be $target.Name
            $matchingIds = @($allStatuses | Where-Object { $_.Name -eq $target.Name } | ForEach-Object { $_.Id })
            $matchingIds | Should -Contain $statusByName[0].Id
        }
    }
}
