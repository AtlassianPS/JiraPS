#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe 'Get-JiraFilterPermission' -Tag 'Unit' {

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

        $sampleResponse = @"
{
  "id": 10000,
  "type": "global"
}
"@
        #endregion Definitions

        #region Mocks
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            $jiraServer
        }

        Mock ConvertTo-JiraFilter -ModuleName JiraPS { }

        Mock Get-JiraFilter -ModuleName JiraPS {
            foreach ($_id in $Id) {
            $basicFilter = New-Object -TypeName PSCustomObject -Property @{
                Id = $Id
                RestUrl = "$jiraServer/rest/api/2/filter/$Id"
            }
            $basicFilter.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
            $basicFilter
        }
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/filter/*/permission"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $sampleResponse
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraFilterPermission

            defParam $command 'Filter'
            defParam $command 'Id'
            defParam $command 'Credential'
        }

        Context "Behavior testing" {
            It "Retrieves the permissions of a Filter by Object" {
                { Get-JiraFilter -Id 23456 | Get-JiraFilterPermission } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/filter/23456/permission'
                }
            }

            It "Retrieves the permissions of a Filter by Id" {
                { 23456 | Get-JiraFilterPermission } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/filter/23456/permission'
                }
            }
        }

        Context "Input testing" {
            It "finds the filter by Id" {
                { Get-JiraFilterPermission -Id 23456 } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "does not accept negative Ids" {
                { Get-JiraFilterPermission -Id -1 } | Should -Throw
            }

            It "can process multiple Ids" {
                { Get-JiraFilterPermission -Id 23456, 23456 } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
            }

            It "allows for the filter to be passed over the pipeline" {
                { Get-JiraFilter -Id 23456 | Get-JiraFilterPermission } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "can ony process one Filter objects" {
                $filter = @()
                $filter += Get-JiraFilter -Id 23456
                $filter += Get-JiraFilter -Id 23456

                { Get-JiraFilterPermission -Filter $filter } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
            }

            It "resolves positional parameters" {
                { Get-JiraFilterPermission 23456 } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It

                $filter = Get-JiraFilter -Id 23456
                { Get-JiraFilterPermission $filter } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
            }
        }
    }
}
