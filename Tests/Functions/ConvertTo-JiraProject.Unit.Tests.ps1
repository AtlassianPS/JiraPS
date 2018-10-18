#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "ConvertTo-JiraProject" -Tag 'Unit' {

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

        $projectKey = 'IT'
        $projectId = '10003'
        $projectName = 'Information Technology'

        $sampleJson = @"
{
    "expand": "description,lead,url,projectKeys",
    "self": "$jiraServer/rest/api/2/project/$projectId",
    "id": "$projectId",
    "key": "$projectKey",
    "name": "$projectName",
    "description": "",
    "lead": {
        "self":  "$jiraServer/rest/api/2/user?username=admin",
        "key": "admin",
        "name": "admin",
        "avatarUrls": {
            "48x48": "$jiraServer/secure/useravatar?ownerId=admin\u0026avatarId=10903",
            "24x24": "$jiraServer/secure/useravatar?size=small\u0026ownerId=admin\u0026avatarId=10903",
            "16x16": "$jiraServer/secure/useravatar?size=xsmall\u0026ownerId=admin\u0026avatarId=10903",
            "32x32": "$jiraServer/secure/useravatar?size=medium\u0026ownerId=admin\u0026avatarId=10903"
        },
        "displayName": "Admin",
        "active": true
    },
    "url": "$jiraServer/browse/HCC/",
    "avatarUrls": {
        "48x48": "$jiraServer/secure/projectavatar?pid=16802\u0026avatarId=10011",
        "24x24": "$jiraServer/secure/projectavatar?size=small\u0026pid=16802\u0026avatarId=10011",
        "16x16": "$jiraServer/secure/projectavatar?size=xsmall\u0026pid=16802\u0026avatarId=10011",
        "32x32": "$jiraServer/secure/projectavatar?size=medium\u0026pid=16802\u0026avatarId=10011"
    },
    "projectKeys": "HCC",
    "projectCategory": {
        "self": "$jiraServer/rest/api/latest/projectCategory/10000",
        "id":  "10000",
        "name":  "Home Connect",
        "description":  "Home Connect Projects"
    },
    "projectTypeKey": "software",
    "components": {
        "self": "$jiraServer/rest/api/2/component/11000",
        "id": "11000",
        "description": "A test component",
        "name": "test component"
    }
}
"@
        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        $r = ConvertTo-JiraProject -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.Project'

        defProp $r 'Id' $projectId
        defProp $r 'Key' $projectKey
        defProp $r 'Name' $projectName
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/project/$projectId"

        checkPsType $r.Lead 'JiraPS.User'
        # checkPsType $r.IssueTypes 'JiraPS.IssueType'
    }
}
