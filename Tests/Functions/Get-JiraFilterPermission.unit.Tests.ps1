#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

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

        . "$PSScriptRoot/../Shared.ps1"

        #region Definitions
        $jiraServer = "https://jira.example.com"

        $sampleResponse = @"
{
  "id": 10000,
  "type": "global"
}
"@

        # Helper function to create test JiraFilter object
        function Get-TestJiraFilter {
            param($Id = 23456)
            $object = New-Object -TypeName PSCustomObject -Property @{
                Id = $Id
                RestUrl = "$jiraServer/rest/api/2/filter/$Id"
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
            $object
        }
        #endregion Definitions

        #region Mocks
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            $jiraServer
        }

        Mock ConvertTo-JiraFilter -ModuleName JiraPS { }

        Mock Get-JiraFilter -ModuleName JiraPS {
            foreach ($_id in $Id) {
                Get-TestJiraFilter -Id $_id
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
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name Get-JiraFilterPermission

            defParam $command 'Filter'
            defParam $command 'Id'
            defParam $command 'Credential'
        }
    }

    Context "Behavior testing" {
        It "Retrieves the permissions of a Filter by Object" {
            { Get-TestJiraFilter -Id 23456 | Get-JiraFilterPermission } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like '*/rest/api/*/filter/23456/permission'
            }
        }

        It "Retrieves the permissions of a Filter by Id" {
            { 23456 | Get-JiraFilterPermission } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like '*/rest/api/*/filter/23456/permission'
            }
        }
    }

    Context "Input testing" {
        It "finds the filter by Id" {
            { Get-JiraFilterPermission -Id 23456 } | Should -Not -Throw

            Should -Invoke -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1
        }

        It "does not accept negative Ids" {
            { Get-JiraFilterPermission -Id -1 } | Should -Throw
        }

        It "can process multiple Ids" {
            { Get-JiraFilterPermission -Id 23456, 23456 } | Should -Not -Throw

            Should -Invoke -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2
        }

        It "allows for the filter to be passed over the pipeline" {
            { Get-TestJiraFilter -Id 23456 | Get-JiraFilterPermission } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
        }

        It "can only process multiple Filter objects" {
            $filter = @()
            $filter += Get-TestJiraFilter -Id 23456
            $filter += Get-TestJiraFilter -Id 23456

            { Get-JiraFilterPermission -Filter $filter } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2
        }

        It "resolves positional parameters" {
            { Get-JiraFilterPermission 23456 } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1

            $filter = Get-TestJiraFilter -Id 23456
            { Get-JiraFilterPermission $filter } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2
        }
    }
}
