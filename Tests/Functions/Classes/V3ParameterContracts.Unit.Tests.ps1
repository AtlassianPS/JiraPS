#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {

    Describe 'v3 public object binding' -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            Mock Test-JiraCloudServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Test-JiraCloudServer' 'Credential'
                $false
            }
            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject', 'Credential'
                [AtlassianPS.JiraPS.Issue]@{
                    Key     = 'TEST-1'
                    RestUrl = 'https://jira.example/rest/api/2/issue/1'
                }
            }
            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri', 'Body'
            }
            Mock Get-JiraFilterOperation -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilter' 'InputObject', 'Credential'
                [AtlassianPS.JiraPS.Filter]@{
                    Id      = '10'
                    Name    = 'Filter'
                    RestUrl = 'https://jira.example/rest/api/2/filter/10'
                }
            }
        }

        It 'sends group visibility for <command> on <deployment>' -TestCases @(
            @{ command = 'Add-JiraIssueComment'; deployment = 'Cloud'; cloud = $true; suffix = 'comment' }
            @{ command = 'Add-JiraIssueComment'; deployment = 'DC'; cloud = $false; suffix = 'comment' }
            @{ command = 'Add-JiraIssueWorklog'; deployment = 'Cloud'; cloud = $true; suffix = 'worklog' }
            @{ command = 'Add-JiraIssueWorklog'; deployment = 'DC'; cloud = $false; suffix = 'worklog' }
        ) {
            param($command, $cloud, $suffix)
            Mock Test-JiraCloudServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Test-JiraCloudServer' 'Credential'
                $cloud
            }
            $arguments = @{
                Issue      = 'TEST-1'
                Comment    = 'Restricted'
                Visibility = @{
                    Type       = 'group'
                    Value      = 'members'
                    Identifier = 'g1'
                }
                Confirm    = $false
            }
            if ($command -eq 'Add-JiraIssueWorklog') {
                $arguments.TimeSpent = [timespan]::FromHours(1)
                $arguments.DateStarted = [datetime]'2026-10-10T10:00:00'
            }
            & $command @arguments
            $apiVersion = if ($cloud) { '3' } else { '2' }
            Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                $payload = $Body | ConvertFrom-Json
                $Uri -eq "https://jira.example/rest/api/$apiVersion/issue/1/$suffix" -and
                $payload.visibility.type -eq 'group' -and
                $payload.visibility.value -eq 'members' -and
                $payload.visibility.identifier -eq 'g1'
            }
        }

        It 'rejects invalid visibility before REST for <value>' -TestCases @(
            @{
                value = @{
                    Type  = 'project'
                    Value = 'x'
                }
            }
            @{
                value = @{
                    Type  = 'role'
                    Value = ' '
                }
            }
            @{
                value = @{
                    Value = 'members'
                }
            }
        ) {
            param($value)
            { Add-JiraIssueComment -Issue TEST-1 -Comment x -Visibility $value -ErrorAction Stop } | Should -Throw -ExpectedMessage '*Visibility*'
            Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Times 0 -Exactly
        }

        It 'binds a returned status by its ID rather than display name' {
            [AtlassianPS.JiraPS.Status]@{ Id = 7; Name = 'In progress' } | Get-JiraStatus
            Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://jira.example.com/rest/api/latest/status/7'
            }
        }

        It 'binds project results by key rather than display name' {
            [AtlassianPS.JiraPS.Project]@{ Key = 'TEST'; Name = 'Project display name' } | Get-JiraProject
            Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                $Uri -like '/rest/api/2/project/TEST?*'
            }
        }

        It 'binds an ID-only project through the competing version parameter sets' {
            Mock Get-JiraProjectOperation -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraProject' 'Project', 'Credential'
                [AtlassianPS.JiraPS.Project]@{ Id = '123'; Key = 'TEST' }
            }
            [AtlassianPS.JiraPS.Project]@{ Id = '123' } | Get-JiraVersion
            Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                $Uri -like '/rest/api/2/project/TEST/*'
            }
            Should -Invoke Get-JiraProjectOperation -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                $Project.Key -eq '123'
            }
        }

        It 'uses remote link identifiers without narrowing a long to Int32' {
            Remove-JiraRemoteLink -Issue TEST-1 -Link ([AtlassianPS.JiraPS.Link]@{
                    Id = 4294967296
                }) -Confirm:$false
            Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                $Uri -eq '/rest/api/2/issue/TEST-1/remotelink/4294967296'
            }
        }

        It 'accepts filter ID aliases and permission objects in positional calls' {
            Remove-JiraFilterPermission 10 ([AtlassianPS.JiraPS.FilterPermission]@{ Id = 20 }) -Confirm:$false
            Remove-JiraFilterPermission -FilterId 10 -PermissionId 21 -Confirm:$false
            Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://jira.example/rest/api/2/filter/10/permission/20'
            }
            Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://jira.example/rest/api/2/filter/10/permission/21'
            }
        }

        It 'keeps legacy permission IDs when a filter is piped into deletion' {
            $legacy = [PSCustomObject]@{
                Id                = '10'
                RestUrl           = 'https://jira.example/rest/api/2/filter/10'
                FilterPermissions = @(
                    [PSCustomObject]@{ Id = 20 }
                )
            }
            $legacy.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Filter')
            $legacy | Remove-JiraFilterPermission -Permission 20 -Confirm:$false
            Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://jira.example/rest/api/2/filter/10/permission/20'
            }
        }

        It 'deletes multiple typed filters and numeric IDs without scalar reassignments' {
            @(
                [AtlassianPS.JiraPS.Filter]@{ Id = '10'; RestUrl = 'https://jira.example/rest/api/2/filter/10' }
                [AtlassianPS.JiraPS.Filter]@{ Id = '11'; RestUrl = 'https://jira.example/rest/api/2/filter/11' }
            ) | Remove-JiraFilter -Confirm:$false
            Remove-JiraFilter -Id 10, 11 -Confirm:$false
            Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Times 4 -Exactly -ParameterFilter {
                $Method -eq 'DELETE'
            }
        }

        It 'rejects unrelated domain objects when there is no alternative pipeline parameter set' {
            { Get-JiraStatus -Status ([AtlassianPS.JiraPS.Project]@{ Key = 'TEST' }) -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*AtlassianPS.JiraPS.Status*'
        }

        It 'keeps explicit empty permissions and typed owner details during filter conversion' {
            $owner = [AtlassianPS.JiraPS.User]@{
                Name      = 'dc-user'
                Groups    = @('devs')
                AvatarUrl = [System.Collections.Generic.Dictionary[string, uri]]::new()
            }
            $owner.AvatarUrl['16x16'] = 'https://jira.example/avatar.png'
            $filter = [AtlassianPS.JiraPS.Filter]@{
                Id                = '10'
                Owner             = $owner
                FilterPermissions = @(
                    [AtlassianPS.JiraPS.FilterPermission]@{ Id = 20 }
                )
            }
            $result = ConvertTo-JiraFilter -InputObject $filter -FilterPermissions @()
            $result.FilterPermissions.Count | Should -Be 0
            $result.Owner.Groups | Should -Be @('devs')
            $result.Owner.AvatarUrl['16x16'] | Should -Be ([uri]'https://jira.example/avatar.png')
        }
    }
}
