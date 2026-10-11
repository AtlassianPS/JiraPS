#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Remove-JiraFilterPermission" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = "https://jira.example.com"

            $script:filterPermission1 = New-Object -TypeName PSCustomObject -Property @{ Id = 1111 }
            $filterPermission1.PSObject.TypeNames.Insert(0, 'JiraPS.FilterPermission')
            $script:filterPermission2 = New-Object -TypeName PSCustomObject -Property @{ Id = 2222 }
            $filterPermission2.Id = 2222
            $script:fullFilter = New-Object -TypeName PSCustomObject -Property @{
                Id                = 12345
                RestUrl           = "$jiraServer/rest/api/2/filter/12345"
                FilterPermissions = @(
                    $filterPermission1
                    $filterPermission2
                )
            }
            $fullFilter.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Filter')
            $script:basicFilter = New-Object -TypeName PSCustomObject -Property @{
                Id      = 23456
                RestUrl = "$jiraServer/rest/api/2/filter/23456"
            }
            $basicFilter.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Filter')
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilter' 'Id'
                $basicFilter
            }

            Mock Get-JiraFilterPermission -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilterPermission' 'Id'
                $fullFilter
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/*/filter/*/permission*" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Remove-JiraFilterPermission
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Filter'; type = "AtlassianPS.JiraPS.Filter" }
                    @{ parameter = 'Permission'; type = "AtlassianPS.JiraPS.FilterPermission[]" }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Permission Deletion" {
                It "uses credentials for both filter hydration and permission deletion" {
                    $credential = [PSCredential]::new('filter-owner', [SecureString]::new())
                    Remove-JiraFilterPermission -FilterId 23456 -PermissionId 1111 -Credential $credential -Confirm:$false

                    Should -Invoke Get-JiraFilter -Exactly -Times 1 -ParameterFilter { $Credential.UserName -eq 'filter-owner' -and $ErrorAction -eq 'Stop' }
                    Should -Invoke Invoke-JiraMethod -Exactly -Times 1 -ParameterFilter { $Credential.UserName -eq 'filter-owner' }
                }

                It "does not delete permissions under WhatIf" {
                    Remove-JiraFilterPermission -Filter $fullFilter -WhatIf

                    Should -Invoke Invoke-JiraMethod -Exactly -Times 0
                }

                It "uses a typed filter and permission without an extra filter lookup" {
                    $filter = [AtlassianPS.JiraPS.Filter]@{ Id = '12345'; Name = 'Test filter'; RestUrl = "$jiraServer/rest/api/2/filter/12345" }
                    $permission = [AtlassianPS.JiraPS.FilterPermission]@{ Id = 1111 }
                    $filter | Remove-JiraFilterPermission -Permission $permission -Confirm:$false

                    Should -Invoke Get-JiraFilter -Exactly -Times 0
                    Should -Invoke Invoke-JiraMethod -Exactly -Times 1 -ParameterFilter { $URI -like '*/filter/12345/permission/1111' }
                }

                It "preserves explicit permissions across pipeline filters with <parameterName>" -TestCases @(
                    @{ parameterName = 'Permission' }
                    @{ parameterName = 'PermissionId' }
                ) {
                    param($parameterName)
                    $parameters = @{
                        $parameterName = @(
                            [AtlassianPS.JiraPS.FilterPermission]@{ Id = 3333 }
                            [AtlassianPS.JiraPS.FilterPermission]@{ Id = 4444 }
                        )
                        Confirm        = $false
                    }
                    @($fullFilter, $basicFilter) | Remove-JiraFilterPermission @parameters

                    Should -Invoke Invoke-JiraMethod -Exactly -Times 4
                    Should -Invoke Invoke-JiraMethod -Exactly -Times 1 -ParameterFilter { $URI -like '*/filter/12345/permission/3333' }
                    Should -Invoke Invoke-JiraMethod -Exactly -Times 1 -ParameterFilter { $URI -like '*/filter/12345/permission/4444' }
                    Should -Invoke Invoke-JiraMethod -Exactly -Times 1 -ParameterFilter { $URI -like '*/filter/23456/permission/3333' }
                    Should -Invoke Invoke-JiraMethod -Exactly -Times 1 -ParameterFilter { $URI -like '*/filter/23456/permission/4444' }
                }

                It "preserves zero permission IDs accepted by the former UInt32 parameter" {
                    Remove-JiraFilterPermission -Filter $basicFilter -PermissionId 0 -Confirm:$false

                    Should -Invoke Invoke-JiraMethod -Exactly -Times 1 -ParameterFilter { $URI -like '*/filter/23456/permission/0' }
                }

                It "supports 64-bit permission IDs without truncating them" {
                    Remove-JiraFilterPermission -Filter $basicFilter -PermissionId '4294967296' -Confirm:$false

                    Should -Invoke Invoke-JiraMethod -Exactly -Times 1 -ParameterFilter { $URI -like '*/filter/23456/permission/4294967296' }
                }

                It "keeps embedded zero permission IDs distinct from missing IDs" {
                    $filter = [AtlassianPS.JiraPS.Filter]@{
                        Id                = '12345'
                        RestUrl           = "$jiraServer/rest/api/2/filter/12345"
                        FilterPermissions = @([AtlassianPS.JiraPS.FilterPermission]@{ Id = 0 })
                    }
                    Remove-JiraFilterPermission -Filter $filter -Confirm:$false

                    Should -Invoke Invoke-JiraMethod -Exactly -Times 1 -ParameterFilter { $URI -like '*/permission/0' }
                }

                It "Deletes Permission from Filter Object" {
                    {
                        Get-JiraFilterPermission -Id 1 | Remove-JiraFilterPermission
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Delete' -and
                        $URI -like '*/rest/api/*/filter/12345/permission/1111'
                    }
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Delete' -and
                        $URI -like '*/rest/api/*/filter/12345/permission/2222'
                    }
                }

                It "Deletes Permission from FilterId + PermissionId" {
                    {
                        Remove-JiraFilterPermission -FilterId 1 -PermissionId 3333, 4444
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Delete' -and
                        $URI -like '*/rest/api/*/filter/23456/permission/3333'
                    }
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Delete' -and
                        $URI -like '*/rest/api/*/filter/23456/permission/4444'
                    }
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                It "finds the filter by FilterId" {
                    { Remove-JiraFilterPermission -FilterId 1 -PermissionId 1111 } | Should -Not -Throw

                    Should -Invoke -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1
                }

                It "can process multiple PermissionIds" {
                    { Remove-JiraFilterPermission -FilterId 1 -PermissionId 1111, 2222 } | Should -Not -Throw
                }

                It "allows for the filter to be passed over the pipeline" {
                    { Get-JiraFilterPermission -Id 1 | Remove-JiraFilterPermission } | Should -Not -Throw
                }

                It "resolves positional parameters" {
                    { Remove-JiraFilterPermission 12345 1111 } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1

                    $filter = Get-JiraFilterPermission -Id 1
                    { Remove-JiraFilterPermission $filter } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 3
                }
            }

            Context "Negative cases" {
                It "rejects missing or negative IDs in permission objects" -TestCases @(
                    @{ permissionId = $null }
                    @{ permissionId = -1 }
                ) {
                    param($permissionId)
                    $permission = [AtlassianPS.JiraPS.FilterPermission]@{ Id = $permissionId }
                    { Remove-JiraFilterPermission -Filter $basicFilter -PermissionId $permission } | Should -Throw -ExpectedMessage '*non-negative numeric permission IDs*'

                    Should -Invoke Invoke-JiraMethod -Exactly -Times 0
                }

                It "validates all explicit permissions before deleting any" -TestCases @(
                    @{ permissionId = $null }
                    @{ permissionId = -1 }
                ) {
                    param($permissionId)
                    $permissions = @(
                        [AtlassianPS.JiraPS.FilterPermission]@{ Id = 1111 }
                        [AtlassianPS.JiraPS.FilterPermission]@{ Id = $permissionId }
                    )

                    { Remove-JiraFilterPermission -Filter $basicFilter -Permission $permissions -Confirm:$false } |
                        Should -Throw -ExpectedMessage '*non-negative numeric permission IDs*' -ErrorId 'ParameterValue.InvalidFilterPermissionId*'

                    Should -Invoke Invoke-JiraMethod -Exactly -Times 0
                }

                It "validates all embedded permissions before deleting any" -TestCases @(
                    @{ permissionId = $null }
                    @{ permissionId = -1 }
                ) {
                    param($permissionId)
                    $filter = [AtlassianPS.JiraPS.Filter]@{
                        Id                = '12345'
                        RestUrl           = "$jiraServer/rest/api/2/filter/12345"
                        FilterPermissions = @(
                            [AtlassianPS.JiraPS.FilterPermission]@{ Id = 1111 }
                            [AtlassianPS.JiraPS.FilterPermission]@{ Id = $permissionId }
                        )
                    }
                    { Remove-JiraFilterPermission -Filter $filter } | Should -Throw -ExpectedMessage '*non-negative numeric permission IDs*' -ErrorId 'ParameterValue.InvalidFilterPermissionId*'

                    Should -Invoke Invoke-JiraMethod -Exactly -Times 0
                }

                It "rejects null entries in embedded permission arrays before deleting any" {
                    $filter = [AtlassianPS.JiraPS.Filter]@{
                        Id                = '12345'
                        RestUrl           = "$jiraServer/rest/api/2/filter/12345"
                        FilterPermissions = @([AtlassianPS.JiraPS.FilterPermission]@{ Id = 1111 }, $null)
                    }
                    { Remove-JiraFilterPermission -Filter $filter } | Should -Throw -ExpectedMessage '*non-negative numeric permission IDs*'

                    Should -Invoke Invoke-JiraMethod -Exactly -Times 0
                }

                It "uses a module argument error when the filter has no permissions" {
                    { Remove-JiraFilterPermission -Filter $basicFilter } | Should -Throw -ExpectedMessage '*Supply Permission*' -ErrorId 'ParameterValue.FilterWithoutPermission*'
                }

                It "validates the -Filter to ensure FilterPermissions" {
                    { Remove-JiraFilterPermission -Filter (Get-JiraFilter -Id 1) } | Should -Throw -ExpectedMessage "*Permission*"
                    { Remove-JiraFilterPermission -Filter (Get-JiraFilterPermission -Id 1) } | Should -Not -Throw
                }

                It "does not accept negative FilterIds" {
                    { Remove-JiraFilterPermission -FilterId -1 -PermissionId 1111 } | Should -Throw -ExpectedMessage "*Filter*"
                }

                It "does not accept negative PermissionIds" {
                    { Remove-JiraFilterPermission -FilterId 1 -PermissionId -1111 } |
                        Should -Throw -ExpectedMessage '*non-negative numeric permission IDs*' -ErrorId 'ParameterValue.InvalidFilterPermissionId*'

                    Should -Invoke Invoke-JiraMethod -Exactly -Times 0
                }

                It "can only process one FilterId" {
                    { Remove-JiraFilterPermission -FilterId 1, 2 -PermissionId 1111 } | Should -Throw -ExpectedMessage "*Filter*"
                }

                It "can only process one Filter objects" {
                    $filter = @()
                    $filter += Get-JiraFilterPermission -Id 1
                    $filter += Get-JiraFilterPermission -Id 1

                    { Remove-JiraFilterPermission -Filter $filter } | Should -Throw -ExpectedMessage "*Filter*"
                }
            }
        }
    }
}
