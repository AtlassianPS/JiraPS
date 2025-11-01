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
    Describe "ConvertTo-JiraFilterPermission" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defProp / checkPsType / checkType)

            $sampleJson = @"
[
  {
    "id": 10000,
    "type": "global"
  },
  {
    "id": 10010,
    "type": "project",
    "project": {
      "self": "$jiraServer/jira/rest/api/2/project/EX",
      "id": "10000",
      "key": "EX",
      "name": "Example",
      "avatarUrls": {
        "48x48": "$jiraServer/jira/secure/projectavatar?size=large&pid=10000",
        "24x24": "$jiraServer/jira/secure/projectavatar?size=small&pid=10000",
        "16x16": "$jiraServer/jira/secure/projectavatar?size=xsmall&pid=10000",
        "32x32": "$jiraServer/jira/secure/projectavatar?size=medium&pid=10000"
      },
      "projectCategory": {
        "self": "$jiraServer/jira/rest/api/2/projectCategory/10000",
        "id": "10000",
        "name": "FIRST",
        "description": "First Project Category"
      },
      "simplified": false
    }
  },
  {
    "id": 10010,
    "type": "project",
    "project": {
      "self": "$jiraServer/jira/rest/api/2/project/MKY",
      "id": "10002",
      "key": "MKY",
      "name": "Example",
      "avatarUrls": {
        "48x48": "$jiraServer/jira/secure/projectavatar?size=large&pid=10002",
        "24x24": "$jiraServer/jira/secure/projectavatar?size=small&pid=10002",
        "16x16": "$jiraServer/jira/secure/projectavatar?size=xsmall&pid=10002",
        "32x32": "$jiraServer/jira/secure/projectavatar?size=medium&pid=10002"
      },
      "projectCategory": {
        "self": "$jiraServer/jira/rest/api/2/projectCategory/10000",
        "id": "10000",
        "name": "FIRST",
        "description": "First Project Category"
      },
      "simplified": false
    },
    "role": {
      "self": "$jiraServer/jira/rest/api/2/project/MKY/role/10360",
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
  },
  {
    "id": 10010,
    "type": "group",
    "group": {
      "name": "jira-administrators",
      "self": "$jiraServer/jira/rest/api/2/group?groupname=jira-administrators"
    }
  }
]
"@

        $sampleObject = ConvertFrom-Json -InputObject $sampleJson
        }

        Context "Sanity checking" {
            It "Creates a PSObject out of JSON input" {
                $r = ConvertTo-JiraFilterPermission -InputObject $sampleObject
                $r | Should -Not -BeNullOrEmpty
            }

            It "Uses correct output type" {
                $r = ConvertTo-JiraFilterPermission -InputObject $sampleObject
                checkType $r "JiraPS.FilterPermission"
            }

            It "Can cast to string" {
                $r = ConvertTo-JiraFilterPermission -InputObject $sampleObject
                castsToString $r
            }

            It "Defines expected properties" {
                $r = ConvertTo-JiraFilterPermission -InputObject $sampleObject
                defProp $r 'Id' @(10000, 10010, 10010, 10010)
                defProp $r 'Type' @('global', 'project', 'project', 'group')
            }

            It "Defines the 'Group' property of type 'JiraPS.Group'" {
                $r = ConvertTo-JiraFilterPermission -InputObject $sampleObject
                checkType $r[3].Group 'JiraPS.Group'
                $r.Group.Name | Should -Be 'jira-administrators'
            }

            It "Defines the 'Project' property of type 'JiraPS.Project'" {
                $r = ConvertTo-JiraFilterPermission -InputObject $sampleObject
                checkType $r[1].Project 'JiraPS.Project'
                $r.Project.Name | Should -Be @('Example', 'Example')
            }

            It "Defines the 'Role' property of type 'JiraPS.ProjectRole'" {
                $r = ConvertTo-JiraFilterPermission -InputObject $sampleObject
                checkType $r[2].Role 'JiraPS.ProjectRole'
                $r.Role.Name | Should -Be 'Developers'
            }
        }
    }
}
