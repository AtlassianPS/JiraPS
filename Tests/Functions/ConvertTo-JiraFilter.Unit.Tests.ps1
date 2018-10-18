#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "ConvertTo-JiraFilter" -Tag 'Unit' {

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

        # Obtained from Atlassian's public JIRA instance
        $sampleJson = @'
{
    "self": "https://jira.atlassian.com/rest/api/latest/filter/12844",
    "id": "12844",
    "name": "All JIRA Bugs",
    "owner": {
        "self": "https://jira.atlassian.com/rest/api/2/user?username=scott@atlassian.com",
        "key": "scott@atlassian.com",
        "name": "scott@atlassian.com",
        "avatarUrls": {
            "16x16": "https://jira.atlassian.com/secure/useravatar?size=xsmall&avatarId=10612",
            "24x24": "https://jira.atlassian.com/secure/useravatar?size=small&avatarId=10612",
            "32x32": "https://jira.atlassian.com/secure/useravatar?size=medium&avatarId=10612",
            "48x48": "https://jira.atlassian.com/secure/useravatar?avatarId=10612"
        },
        "displayName": "Scott Farquhar [Atlassian]",
        "active": true
    },
    "jql": "project = 10240 AND issuetype = 1 ORDER BY key DESC",
    "viewUrl": "https://jira.atlassian.com/secure/IssueNavigator.jspa?mode=hide&requestId=12844",
    "searchUrl": "https://jira.atlassian.com/rest/api/latest/search?jql=project+%3D+10240+AND+issuetype+%3D+1+ORDER+BY+key+DESC",
    "favourite": false,
    "sharePermissions": [
        {
            "id": 10049,
            "type": "global"
        }
    ],
    "sharedUsers": {
        "size": 0,
        "items": [],
        "max-results": 1000,
        "start-index": 0,
        "end-index": 0
    },
    "subscriptions": {
        "size": 0,
        "items": [],
        "max-results": 1000,
        "start-index": 0,
        "end-index": 0
    }
}
'@

    $samplePermission = @"
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

        Mock ConvertTo-JiraFilterPermission -ModuleName JiraPS {
            $i = New-Object -TypeName PSCustomObject -Property @{ Id = 1111 }
            $i.PSObject.TypeNames.Insert(0, 'JiraPS.FilterPermission')
            $i
        }

        $sampleObject = ConvertFrom-Json -InputObject $sampleJson
        $r = ConvertTo-JiraFilter -InputObject $sampleObject -FilterPermission $samplePermission

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.Filter'

        defProp $r 'Id' 12844
        defProp $r 'Name' 'All JIRA Bugs'
        defProp $r 'JQL' 'project = 10240 AND issuetype = 1 ORDER BY key DESC'
        defProp $r 'RestUrl' 'https://jira.atlassian.com/rest/api/latest/filter/12844'
        defProp $r 'ViewUrl' 'https://jira.atlassian.com/secure/IssueNavigator.jspa?mode=hide&requestId=12844'
        defProp $r 'SearchUrl' 'https://jira.atlassian.com/rest/api/latest/search?jql=project+%3D+10240+AND+issuetype+%3D+1+ORDER+BY+key+DESC'
        defProp $r 'Favourite' $false
        It "Defines the 'Favorite' property as an alias of 'Favourite'" {
            ($r | Get-Member -Name Favorite).MemberType | Should -Be "AliasProperty"
        }

        It "Uses output type of 'JiraPS.FilterPermission' for property 'FilterPermissions'" {
            checkType $r.FilterPermissions 'JiraPS.FilterPermission'
        }

        It "uses ConvertTo-JiraFilterPermission" {
            Assert-MockCalled -CommandName ConvertTo-JiraFilterPermission -Module JiraPS -Exactly -Times 1 -Scope Describe
        }
    }
}
