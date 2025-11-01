#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

BeforeDiscovery {
    Remove-Item -Path Env:\BH*
    $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    if ($projectRoot -like "*Release") {
        $projectRoot = (Resolve-Path "$projectRoot/..").Path
    }

    Import-Module BuildHelpers
    Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

    $env:BHManifestToTest = $env:BHPSModuleManifest
    $isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
    if ($isBuild) {
        $Pattern = [regex]::Escape($env:BHProjectPath)

        $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
        $env:BHManifestToTest = $env:BHBuildModuleManifest
    }

    Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    Import-Module $env:BHManifestToTest
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraProjectRole" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defProp / hasProp / checkPsType)

            $sampleJson = @"
[
  {
    "self": "http://www.example.com/jira/rest/api/2/project/MKY/role/10360",
    "name": "Developers",
    "id": 10360,
    "description": "A project role that represents developers in a project",
    "actors": [
      {
        "id": 10240,
        "displayName": "jira-developers",
        "type": "atlassian-group-role-actor",
        "name": "jira-developers"
      },
      {
        "id": 10241,
        "displayName": "Fred F. User",
        "type": "atlassian-user-role-actor",
        "name": "fred"
      }
    ]
  }
]
"@

        $sampleObject = ConvertFrom-Json -InputObject $sampleJson
        }

        Context "Sanity checking" {
            It "Creates a PSObject out of JSON input" {
                $r = ConvertTo-JiraProjectRole -InputObject $sampleObject
                $r | Should -Not -BeNullOrEmpty
            }

            It "Uses correct output type" {
                $r = ConvertTo-JiraProjectRole -InputObject $sampleObject
                checkType $r "JiraPS.ProjectRole"
            }

            It "Can cast to string" {
                $r = ConvertTo-JiraProjectRole -InputObject $sampleObject
                castsToString $r
            }

            It "Defines expected properties" {
                $r = ConvertTo-JiraProjectRole -InputObject $sampleObject
                defProp $r 'Id' 10360
                defProp $r 'Name' "Developers"
                defProp $r 'Description' "A project role that represents developers in a project"
                hasProp $r 'Actors'
                defProp $r 'RestUrl' "http://www.example.com/jira/rest/api/2/project/MKY/role/10360"
            }
        }
    }
}
