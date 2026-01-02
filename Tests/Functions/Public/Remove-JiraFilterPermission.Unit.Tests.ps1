#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
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
            $fullFilter.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
            $script:basicFilter = New-Object -TypeName PSCustomObject -Property @{
                Id      = 23456
                RestUrl = "$jiraServer/rest/api/2/filter/23456"
            }
            $basicFilter.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
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
                    @{ parameter = 'Filter'; type = 'Object' }
                    @{ parameter = 'FilterId'; type = 'UInt32' }
                    @{ parameter = 'PermissionId'; type = 'UInt32[]' }
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
                It "Deletes Permission from Filter Object" {
                    {
                        Get-JiraFilterPermission -Id 1 | Remove-JiraFilterPermission
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Delete' -and
                        $URI -like '*/rest/api/*/filter/12345/permission/1111'
                    }
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Delete' -and
                        $URI -like '*/rest/api/*/filter/12345/permission/2222'
                    }
                }

                It "Deletes Permission from FilterId + PermissionId" {
                    {
                        Remove-JiraFilterPermission -FilterId 1 -PermissionId 3333, 4444
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Delete' -and
                        $URI -like '*/rest/api/*/filter/23456/permission/3333'
                    }
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
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

                    Should -Invoke -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "can process multiple PermissionIds" {
                    { Remove-JiraFilterPermission -FilterId 1 -PermissionId 1111, 2222 } | Should -Not -Throw
                }

                It "allows for the filter to be passed over the pipeline" {
                    { Get-JiraFilterPermission -Id 1 | Remove-JiraFilterPermission } | Should -Not -Throw
                }

                It "resolves positional parameters" {
                    { Remove-JiraFilterPermission 12345 1111 } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It

                    $filter = Get-JiraFilterPermission -Id 1
                    { Remove-JiraFilterPermission $filter } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 3 -Scope It
                }
            }

            Context "Negative cases" {
                It "validates the -Filter to ensure FilterPermissions" {
                    { Remove-JiraFilterPermission -Filter (Get-JiraFilter -Id 1) } | Should -Throw
                    { Remove-JiraFilterPermission -Filter (Get-JiraFilterPermission -Id 1) } | Should -Not -Throw
                }

                It "does not accept negative FilterIds" {
                    { Remove-JiraFilterPermission -FilterId -1 -PermissionId 1111 } | Should -Throw
                }

                It "does not accept negative PermissionIds" {
                    { Remove-JiraFilterPermission -FilterId 1 -PermissionId -1111 } | Should -Throw
                }

                It "can only process one FilterId" {
                    { Remove-JiraFilterPermission -FilterId 1, 2 -PermissionId 1111 } | Should -Throw
                }

                It "can only process one Filter objects" {
                    $filter = @()
                    $filter += Get-JiraFilterPermission -Id 1
                    $filter += Get-JiraFilterPermission -Id 1

                    { Remove-JiraFilterPermission -Filter $filter } | Should -Throw
                }
            }
        }
    }
}
