#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Get-JiraVersion" -Tag 'Unit' {

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

        $jiraServer = 'http://jiraserver.example.com'
        $versionName = '$versionName'
        $versionID1 = 16840
        $versionID2 = 16940
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
        "self" : "$jiraServer/rest/api/latest/version/$versionID1",
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
        "self" : "$jiraServer/rest/api/latest/version/$versionID1",
        "id" : $versionID1,
        "description" : "$versionName1",
        "name" : "$versionName1",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    },
    {
        "self" : "$jiraServer/rest/api/latest/version/$versionID2",
        "id" : $versionID2,
        "description" : "$versionName2",
        "name" : "$versionName2",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    },
    {
        "self" : "$jiraServer/rest/api/latest/version/$versionID3",
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
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraProject -ModuleName JiraPS {
            $Projects = ConvertFrom-Json $JiraProjectData
            $Projects.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
            $Projects | Where-Object {$_.Key -in $Project}
        }

        Mock Get-JiraVersion -ModuleName JiraPS {
            foreach ($_id in $Id) {
                $Version = [PSCustomObject]@{
                    Id          = $_Id
                    Name        = "v1"
                    Description = "My Desccription"
                    Project     = (Get-JiraProject -Project $projectKey)
                    ReleaseDate = (Get-Date "2017-12-01")
                    StartDate   = (Get-Date "2017-01-01")
                    RestUrl     = "$jiraServer/rest/api/latest/version/$_Id"
                }
                $Version.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
                $Version
            }
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

        Context "Sanity checking" {
            $command = Get-Command -Name Remove-JiraVersion

            defParam $command 'Version'
            defParam $command 'Credential'
            defParam $command 'Force'
        }

        Context "Behavior checking" {
            It 'removes a Version using its ID' {
                { Remove-JiraVersion -Version $versionID1 -Force -ErrorAction Stop } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Get-JiraProject' -Times 1 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID1" }
            }
            It 'removes a Version using the Version Object' {
                {
                    $version = Get-JiraVersion -Id $versionID1
                    Remove-JiraVersion $version -Force -ErrorAction Stop
                } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 2 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Get-JiraProject' -Times 2 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID1" }
            }
            It 'removes a Version using several Version Objects' {
                {
                    $version = Get-JiraVersion -Id $versionID1, $versionID2
                    Remove-JiraVersion -Version $version -Force -ErrorAction Stop
                } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 3 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Get-JiraProject' -Times 4 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID1" }
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID2" }
            }
            It 'removes a Version using Version as input over the pipeline' {
                { Get-JiraVersion -Id $versionID1, $versionID2 | Remove-JiraVersion -Force -ErrorAction Stop } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 3 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Get-JiraProject' -Times 4 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID1" }
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID2" }
            }
            It "assert VerifiableMock" {
                Assert-VerifiableMock
            }
        }
    }
}
