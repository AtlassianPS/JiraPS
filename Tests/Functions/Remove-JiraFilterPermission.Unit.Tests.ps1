#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe 'Remove-JiraFilterPermission' -Tag 'Unit' {

BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        if ($projectRoot -like "*Release") {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }

        Import-Module BuildHelpers
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

        $env:BHManifestToTest = $env:BHPSModuleManifest
        $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($script:isBuild) {
            $Pattern = [regex]::Escape($env:BHProjectPath)

            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

        #region Definitions
        $jiraServer = "https://jira.example.com"

        $filterPermission1 = New-Object -TypeName PSCustomObject -Property @{ Id = 1111 }
        $filterPermission1.PSObject.TypeNames.Insert(0, 'JiraPS.FilterPermission')
        $filterPermission2 = New-Object -TypeName PSCustomObject -Property @{ Id = 2222 }
        $filterPermission2.Id = 2222
        $fullFilter = New-Object -TypeName PSCustomObject -Property @{
            Id = 12345
            RestUrl = "$jiraServer/rest/api/2/filter/12345"
            FilterPermissions = @(
                $filterPermission1
                $filterPermission2
            )
        }
        $fullFilter.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
        $basicFilter = New-Object -TypeName PSCustomObject -Property @{
            Id = 23456
            RestUrl = "$jiraServer/rest/api/2/filter/23456"
        }
        $basicFilter.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')

        #endregion Definitions

        #region Mocks
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            $jiraServer
        }

        Mock Get-JiraFilter -ModuleName JiraPS {
            $basicFilter
        }

        Mock Get-JiraFilterPermission -ModuleName JiraPS {
            $fullFilter
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/*/filter/*/permission*"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks

        Context "Sanity checking" {
            $command = Get-Command -Name Remove-JiraFilterPermission

            defParam $command 'Filter'
            defParam $command 'FilterId'
            defParam $command 'PermissionId'
            defParam $command 'Credential'
        }

        Context "Behavior testing" {
            It "Deletes Permission from Filter Object" {
                {
                    Get-JiraFilterPermission -Id 1 | Remove-JiraFilterPermission
                } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Delete' -and
                    $URI -like '*/rest/api/*/filter/12345/permission/1111'
                }
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Delete' -and
                    $URI -like '*/rest/api/*/filter/12345/permission/2222'
                }
            }

            It "Deletes Permission from FilterId + PermissionId" {
                {
                    Remove-JiraFilterPermission -FilterId 1 -PermissionId 3333, 4444
                } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Delete' -and
                    $URI -like '*/rest/api/*/filter/23456/permission/3333'
                }
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Delete' -and
                    $URI -like '*/rest/api/*/filter/23456/permission/4444'
                }
            }
        }

        Context "Input testing" {
            It "validates the -Filter to ensure FilterPermissions" {
                { Remove-JiraFilterPermission -Filter (Get-JiraFilter -Id 1) } | Should -Throw
                { Remove-JiraFilterPermission -Filter (Get-JiraFilterPermission -Id 1) } | Should -Not -Throw
            }

            It "finds the filter by FilterId" {
                { Remove-JiraFilterPermission -FilterId 1 -PermissionId 1111 } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
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

            It "can process multiple PermissionIds" {
                { Remove-JiraFilterPermission -FilterId 1 -PermissionId 1111, 2222 } | Should -Not -Throw
            }

            It "allows for the filter to be passed over the pipeline" {
                { Get-JiraFilterPermission -Id 1 | Remove-JiraFilterPermission } | Should -Not -Throw
            }

            It "can ony process one Filter objects" {
                $filter = @()
                $filter += Get-JiraFilterPermission -Id 1
                $filter += Get-JiraFilterPermission -Id 1

                { Remove-JiraFilterPermission -Filter $filter } | Should -Throw
            }

            It "resolves positional parameters" {
                { Remove-JiraFilterPermission 12345 1111 } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It

                $filter = Get-JiraFilterPermission -Id 1
                { Remove-JiraFilterPermission $filter } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 3 -Scope It
            }
        }
    }
}
