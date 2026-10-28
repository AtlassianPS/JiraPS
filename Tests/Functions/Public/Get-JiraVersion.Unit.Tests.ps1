#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Get-JiraVersion selectors and output limits' -Tag Unit {
        BeforeEach {
            Mock Get-JiraProjectOperation { [AtlassianPS.JiraPS.Project]@{ Key = 'PROJ'; Id = 10 } }
            Mock Invoke-JiraRequest {
                if ($Uri.OriginalString -like '*/project/*') {
                    foreach ($name in @('other', 'release-1', 'release-2', 'other-2')) {
                        [AtlassianPS.JiraPS.Version]@{ Id = '123'; Name = $name }
                    }
                }
                else { [PSCustomObject]@{ id = '123'; name = 'release' } }
            }
        }

        It 'accepts a numeric ID or typed version from the pipeline' -ForEach @(
            @{ Value = '123' }
            @{ Value = [AtlassianPS.JiraPS.Version]@{ Id = '123' } }
        ) {
            $result = $Value | Get-JiraVersion
            $result.Id | Should -Be '123'
            Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter { $Uri -eq '/rest/api/2/version/123' }
        }

        It 'applies First and Skip after matching names' {
            $result = @(Get-JiraVersion -Project PROJ -Name 'release-*' -Skip 1 -First 1)
            $result | Should -HaveCount 1
            $result[0].Name | Should -Be 'release-2'
            Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter { $First -ne 1 -and $Skip -ne 1 }
        }

        It 'uses any-match semantics for multiple patterns without duplicates' {
            $result = @(Get-JiraVersion -Project PROJ -Name 'release-*', '*-1')
            $result.Name -join ',' | Should -Be 'release-1,release-2'
        }

        It 'uses project objects from the pipeline and reports matched totals' {
            $project = [AtlassianPS.JiraPS.Project]@{ Key = 'PROJ' }
            $result = @($project | Get-JiraVersion -Name 'release-*' -IncludeTotalCount -First 1)
            $result | Should -HaveCount 2
            $result[0] | Should -Be 2
            $result[1].Name | Should -Be 'release-1'
        }

        It 'rejects name-only versions with exact-lookup guidance' {
            { Get-JiraVersion -Version 'name-only' } | Should -Throw '*Use -Project and -Name*'
            Should -Invoke Invoke-JiraRequest -Exactly 0
        }
    }
}
