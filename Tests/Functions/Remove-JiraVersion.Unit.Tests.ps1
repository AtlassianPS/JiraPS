#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Remove-JiraVersion" -Tag 'Unit' {

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

        . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defParam / ShowMockInfo)

        $jiraServer = 'http://jiraserver.example.com'
        $versionName = 'versionName'
        $versionName1 = 'versionName1'
        $versionName2 = 'versionName2'
        $versionID1 = 16840
        $versionID2 = 16940
        $versionID3 = 16941
        $projectKey = 'LDD'
        $projectId = '12101'

        $JiraProjectData = @"
[
    {
        "Key" : "$projectKey",
        "Id": "$projectId"
    },
    {
        "Key" : "foo",
        "Id": "99"
    }
]
"@
        $testJsonOne = @"
    {
        "self" : "$jiraServer/rest/api/2/version/$versionID1",
        "id" : $versionID1,
        "description" : "$versionName",
        "name" : "$versionName",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    }
"@
        $testJsonAll = @"
[
    {
        "self" : "$jiraServer/rest/api/2/version/$versionID1",
        "id" : $versionID1,
        "description" : "$versionName1",
        "name" : "$versionName1",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    },
    {
        "self" : "$jiraServer/rest/api/2/version/$versionID2",
        "id" : $versionID2,
        "description" : "$versionName2",
        "name" : "$versionName2",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    },
    {
        "self" : "$jiraServer/rest/api/2/version/$versionID3",
        "id" : $versionID3,
        "description" : "$versionName2",
        "name" : "$versionName2",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    }
}
"@

        #region Mock

        #helper function to generate test JiraProject object
        function Get-TestJiraProject {
            param($Project)
            $Projects = ConvertFrom-Json $JiraProjectData
            $Projects.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
            $Projects | Where-Object {$_.Key -in $Project}
        }

        function Get-TestJiraVersion {
            param($Id)

            foreach ($_id in $Id) {
                $Version = [PSCustomObject]@{
                    Id          = $_Id
                    Name        = "v1"
                    Description = "My Description"
                    Project     = (Get-TestJiraProject -Project $projectKey)
                    ReleaseDate = (Get-Date "2017-12-01")
                    StartDate   = (Get-Date "2017-01-01")
                    RestUrl     = "$jiraServer/rest/api/2/version/$_Id"
                }
                $Version.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
                $Version
            }
        }

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraProject -ModuleName JiraPS {
            Get-TestJiraProject
        }

        Mock Get-JiraVersion -ModuleName JiraPS {
            Get-TestJiraVersion -Id $Id
        }

        Mock ConvertTo-JiraVersion -ModuleName JiraPS {
            $result = New-Object -TypeName PSObject -Property @{
                Id      = $InputObject.Id
                Name    = $InputObject.name
                Project = $InputObject.projectId
                RestUrl = $InputObject.self
            }
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
            $result
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/*/version/$versionID1" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/*/version/$versionID2" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mock
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name Remove-JiraVersion

            defParam $command 'Version'
            defParam $command 'Credential'
            defParam $command 'Force'
        }
    }

        Context "Behavior checking" {
            It 'removes a Version using its ID' {
                { Remove-JiraVersion -Version $versionID1 -Force -ErrorAction Stop } | Should -Not -Throw

                Should -Invoke 'Get-JiraVersion' -ModuleName JiraPS -Exactly -Times 1
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$versionID1" }
            }

            It 'removes a Version using the Version Object' {
                {
                    $version = Get-TestJiraVersion -Id $versionID1
                    Remove-JiraVersion $version -Force -ErrorAction Stop
                } | Should -Not -Throw

                Should -Invoke 'Get-JiraVersion' -ModuleName JiraPS -Exactly -Times 1
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$versionID1" }
            }
            It 'removes a Version using several Version Objects' {
                {
                    $version = Get-TestJiraVersion -Id $versionID1, $versionID2
                    Remove-JiraVersion -Version $version -Force -ErrorAction Stop
                } | Should -Not -Throw

                Should -Invoke 'Get-JiraVersion' -ModuleName JiraPS -Exactly -Times 2
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$versionID1" }
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$versionID2" }
            }
            It 'removes a Version using Version as input over the pipeline' {
                { Get-TestJiraVersion -Id $versionID1, $versionID2 |
                    Remove-JiraVersion -Force -ErrorAction Stop
                } | Should -Not -Throw

                Should -Invoke 'Get-JiraVersion' -ModuleName JiraPS -Exactly -Times 2
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$versionID1" }
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$versionID2" }
            }
        }
}
