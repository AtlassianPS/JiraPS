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
    Describe 'Enum Contracts' -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:environment = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $environment
            $script:fixtures = Get-TestFixture -Environment $environment
            foreach ($required in 'TestProject', 'TestUser', 'TestGroup') {
                if ([string]::IsNullOrWhiteSpace($fixtures[$required])) { throw "Enum integration tests require fixture '$required'." }
            }
            $script:apiRoot = '/rest/api/' + $(if ($fixtures.IsCloud) { '3' } else { '2' })
            $script:role = $null
            $script:filter = $null
            $name = 'JiraPS-EnumContracts-' + [guid]::NewGuid().ToString('N')
            $script:project = Get-JiraProject -Project $fixtures.TestProject -ErrorAction Stop
            $script:group = Get-JiraGroup -GroupName $fixtures.TestGroup -ErrorAction Stop
            $script:role = Invoke-JiraMethod -URI "$apiRoot/role" -Method Post -Body (@{
                    name        = $name
                    description = 'Temporary role for JiraPS enum integration tests'
                } | ConvertTo-Json) -ErrorAction Stop
            $script:roleUri = "$apiRoot/project/$($project.Id)/role/$($role.id)"
            $actors = @{ user = @($fixtures.TestUser) }
            if ($fixtures.IsCloud) { $actors.groupId = @($group.Id) } else { $actors.group = @($group.Name) }
            $null = Invoke-JiraMethod -URI $roleUri -Method Post -Body ($actors | ConvertTo-Json) -ErrorAction Stop
            $script:filter = New-JiraFilter -Name $name -JQL "project = $($project.Key)" -ErrorAction Stop
            $permission = @{
                type          = 'projectRole'
                projectId     = [string]$project.Id
                projectRoleId = [string]$role.id
            }
            if ($fixtures.IsCloud) { $permission.rights = 1 }
            else {
                $permission.view = $true
                $permission.edit = $false
            }
            $null = Invoke-JiraMethod -URI "$apiRoot/filter/$($filter.Id)/permission" -Method Post -Body ($permission | ConvertTo-Json) -ErrorAction Stop
        }

        AfterAll {
            try {
                if ($filter) {
                    Remove-JiraFilter -InputObject $filter -Confirm:$false -ErrorAction Stop
                }
            }
            finally {
                try {
                    if ($role) {
                        $null = Invoke-JiraMethod -URI "$apiRoot/role/$($role.id)" -Method Delete -ErrorAction Stop
                    }
                }
                finally {
                    Remove-JiraSession -ErrorAction SilentlyContinue
                }
            }
        }

        It 'converts a live user role actor' {
            $response = Invoke-JiraMethod -URI $roleUri -ErrorAction Stop
            $actor = @($response.actors | Where-Object type -EQ 'atlassian-user-role-actor')
            $actor.Count | Should -Be 1
            $converted = ConvertTo-JiraProjectRole -InputObject $response
            $actual = @($converted.Actors | Where-Object Id -EQ $actor[0].id)
            $actual.Count | Should -Be 1
            $actual[0].Type | Should -BeOfType ([AtlassianPS.JiraPS.ActorType])
            $actual[0].Type | Should -Be ([AtlassianPS.JiraPS.ActorType]::AtlassianUserRoleActor)
        }

        It 'converts a live group role actor' {
            $response = Invoke-JiraMethod -URI $roleUri -ErrorAction Stop
            $actor = @($response.actors | Where-Object type -EQ 'atlassian-group-role-actor')
            $actor.Count | Should -Be 1
            $converted = ConvertTo-JiraProjectRole -InputObject $response
            $actual = @($converted.Actors | Where-Object Id -EQ $actor[0].id)
            $actual.Count | Should -Be 1
            $actual[0].Type | Should -BeOfType ([AtlassianPS.JiraPS.ActorType])
            $actual[0].Type | Should -Be ([AtlassianPS.JiraPS.ActorType]::AtlassianGroupRoleActor)
        }

        It 'converts a live project-role filter share' {
            $response = @(Invoke-JiraMethod -URI "$apiRoot/filter/$($filter.Id)/permission" -ErrorAction Stop)
            $permission = @($response | Where-Object { $_.project.id -eq $project.Id -and $_.role.id -eq $role.id })
            $permission.Count | Should -Be 1 -Because "the live response must contain the created project-role share: $($response | ConvertTo-Json -Depth 10 -Compress)"
            $permission[0].type | Should -Be 'project'
            $converted = Get-JiraFilterPermission -Filter $filter -ErrorAction Stop
            $actual = @($converted.FilterPermissions | Where-Object Id -EQ $permission[0].id)
            $actual.Count | Should -Be 1
            $actual[0].Type | Should -BeOfType ([AtlassianPS.JiraPS.FilterShareType])
            $actual[0].Type | Should -Be ([AtlassianPS.JiraPS.FilterShareType]::PROJECT)
            $actual[0].Project.Id | Should -Be $project.Id
            $actual[0].Role.Id | Should -Be $role.id
        }
    }
}
