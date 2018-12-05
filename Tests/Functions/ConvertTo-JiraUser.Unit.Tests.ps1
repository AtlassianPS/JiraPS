#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "ConvertTo-JiraUser" -Tag 'Unit' {

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
        $username = 'powershell-test'
        $displayName = 'PowerShell Test User'
        $email = 'noreply@example.com'

        $sampleJson = @"
{
    "self":"$jiraServer/rest/api/2/user?username=$username",
    "key":"$username",
    "accountId":"500058:1500a9f1-0000-42b3-0000-ab8900008d00",
    "name":"$username",
    "emailAddress":"$email",
    "avatarUrls":{
        "16x16":"https://avatar-cdn.atlassian.com/a35295e666453af3d0adb689d8da7934?s=16&d=https%3A%2F%2Fsecure.gravatar.com%2Favatar%2Fa35295e666453af3d0adb689d8da7934%3Fd%3Dmm%26s%3D16%26noRedirect%3Dtrue",
        "24x24":"https://avatar-cdn.atlassian.com/a35295e666453af3d0adb689d8da7934?s=24&d=https%3A%2F%2Fsecure.gravatar.com%2Favatar%2Fa35295e666453af3d0adb689d8da7934%3Fd%3Dmm%26s%3D24%26noRedirect%3Dtrue",
        "32x32":"https://avatar-cdn.atlassian.com/a35295e666453af3d0adb689d8da7934?s=32&d=https%3A%2F%2Fsecure.gravatar.com%2Favatar%2Fa35295e666453af3d0adb689d8da7934%3Fd%3Dmm%26s%3D32%26noRedirect%3Dtrue",
        "48x48":"https://avatar-cdn.atlassian.com/a35295e666453af3d0adb689d8da7934?s=48&d=https%3A%2F%2Fsecure.gravatar.com%2Favatar%2Fa35295e666453af3d0adb689d8da7934%3Fd%3Dmm% 26s%3D48%26noRedirect%3Dtrue"
    },
    "displayName":"$displayName",
    "active":true,
    "timeZone":"Europe/Berlin",
    "locale":"en_US",
    "groups":{
        "size":4,
        "items":[
            {
                "name":"administrators",
                "self":"$jiraServer/rest/api/2/group?groupname=administrators"
            },
            {
                "name":"balsamiq-mockups-editors",
                "self":"$jiraServer/rest/api/2/group?groupname=balsamiq-mockups-editors"
            },
            {
                "name":"jira-administrators",
                "self":"$jiraServer/rest/api/2/group?groupname=jira-administrators"
            },
            {
                "name":"site-admins",
                "self":"$jiraServer/rest/api/2/group?groupname=site-admins"
            }
        ]
    },
    "applicationRoles":{
        "size":3,
        "items":[]
    },
    "expand":"groups,applicationRoles"
}
"@
        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        $r = ConvertTo-JiraUser -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.User'

        defProp $r 'Key' $username
        defProp $r 'AccountId' "500058:1500a9f1-0000-42b3-0000-ab8900008d00"
        defProp $r 'Name' $username
        defProp $r 'DisplayName' $displayName
        defProp $r 'EmailAddress' $email
        defProp $r 'Active' $true
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/user?username=$username"
        hasProp $r 'AvatarUrl'
        defProp $r 'TimeZone' "Europe/Berlin"
        defProp $r 'Locale' "en_Us"
        It "Defines the 'Group' property" {
            $r.Groups.Count | Should Be 4
        }
    }
}
