#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $environment = Initialize-IntegrationEnvironment
        $script:Skip = $environment.ReadOnly
    }
}

InModuleScope JiraPS {
    Describe "Filter Permissions" -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:environment = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $environment
            $script:fixtures = Get-TestFixture -Environment $environment
            $script:createdFilters = [System.Collections.ArrayList]::new()
        }

        AfterAll {
            try {
                foreach ($filter in $script:createdFilters) {
                    Remove-JiraFilter -InputObject $filter -Confirm:$false -ErrorAction Stop
                }
            }
            finally { Remove-JiraSession -ErrorAction SilentlyContinue }
        }

        It "adds and removes a project share using typed filter permissions" {
            if ([string]::IsNullOrWhiteSpace($fixtures.TestProject)) { throw "Filter permission integration tests require fixture 'TestProject'." }
            $project = Get-JiraProject -Project $fixtures.TestProject -ErrorAction Stop
            $filter = New-JiraFilter -Name (New-TestResourceName -Type "FilterPermission") -JQL "project = $($project.Key)" -ErrorAction Stop
            $null = $script:createdFilters.Add($filter)

            $shared = Add-JiraFilterPermission -Filter $filter -Type Project -Value $project.Id -Confirm:$false -ErrorAction Stop
            $shared | Should -BeOfType ([AtlassianPS.JiraPS.Filter])
            $permission = @($shared.FilterPermissions | Where-Object { $_.Project.Id -eq $project.Id })
            $permission.Count | Should -Be 1
            $permission[0] | Should -BeOfType ([AtlassianPS.JiraPS.FilterPermission])
            $permission[0].Id | Should -Not -BeNullOrEmpty
            $permission[0].Type | Should -Be ([AtlassianPS.JiraPS.FilterShareType]::PROJECT)

            $persisted = Get-JiraFilterPermission -Filter $filter -ErrorAction Stop
            @($persisted.FilterPermissions | Where-Object Id -EQ $permission[0].Id).Count | Should -Be 1

            Remove-JiraFilterPermission -Filter $shared -Permission $permission[0] -Confirm:$false -ErrorAction Stop

            $updated = Get-JiraFilterPermission -Filter $filter -ErrorAction Stop
            @($updated.FilterPermissions | Where-Object Id -EQ $permission[0].Id).Count | Should -Be 0
        }
    }
}
