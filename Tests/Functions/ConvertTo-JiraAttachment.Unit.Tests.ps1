#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "ConvertTo-JiraAttachment" -Tag 'Unit' {

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

        $attachmentID1 = "270709"
        $attachmentName1 = "Nav2-HCF.PNG"
        $attachmentID2 = "270656"

        $sampleJson = @"
[
    {
        "self":  "$jiraServer/rest/api/2/attachment/$attachmentID1",
        "id":  "$attachmentID1",
        "filename":  "$attachmentName1",
        "author":  {
            "self":  "$jiraServer/rest/api/2/user?username=JonDoe",
            "name":  "JonDoe",
            "key":  "JonDoe",
            "emailAddress":  "JonDoe@server.com",
            "avatarUrls":  {},
            "displayName":  "Doe, Jon",
            "active":  true,
            "timeZone":  "Europe/Berlin"
        },
        "created":  "2017-05-30T11:20:34.000+0000",
        "size":  366272,
        "mimeType":  "image/png",
        "content":  "$jiraServer/secure/attachment/$attachmentID1/$attachmentName1",
        "thumbnail":  "$jiraServer/secure/thumbnail/$attachmentID1/_thumb_$attachmentID1.png"
    },
    {
        "self":  "$jiraServer/rest/api/2/attachment/$attachmentID2",
        "id":  "$attachmentID2",
        "filename":  "Nav-HCF.PNG",
        "author":  {
            "self":  "$jiraServer/rest/api/2/user?username=JonDoe",
            "name":  "JonDoe",
            "key":  "JonDoe",
            "emailAddress":  "JonDoe@server.com",
            "avatarUrls":  {},
            "displayName":  "Doe, Jon",
            "active":  true,
            "timeZone":  "Europe/Berlin"
        },
        "created":  "2017-05-30T09:26:17.000+0000",
        "size":  548806,
        "mimeType":  "image/png",
        "content":  "$jiraServer/secure/attachment/$attachmentID2/Nav-HCF.PNG",
        "thumbnail":  "$jiraServer/secure/thumbnail/$attachmentID2/_thumb_$attachmentID2.png"
    }
]
"@

        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        $r = ConvertTo-JiraAttachment -InputObject $sampleObject
        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.Attachment'

        defProp $r[0] 'Id' $attachmentID1
        defProp $r[0] 'FileName' $attachmentName1
        It "Defines Date fields as Date objects" {
            $r[0].created | Should Not BeNullOrEmpty
            checkType $r[0].created 'System.DateTime'
        }
        It "Defines Author field as User objects" {
            $r[0].author | Should Not BeNullOrEmpty
            checkType $r[0].author 'JiraPS.User'
        }
        It "Defines the 'self' property" {
            $r[0].self | Should Not BeNullOrEmpty
        }
        It "Defines the 'size' property" {
            $r[0].size | Should Not BeNullOrEmpty
            checkType $r[0].size 'System.Int32'
        }
        It "Defines the 'content' property" {
            $r[0].content | Should Not BeNullOrEmpty
        }
        defProp $r[0] 'mimeType' 'image/png'
        It "Defines the 'thumbnail' property" {
            $r[0].thumbnail | Should Not BeNullOrEmpty
        }

        It "Handles pipeline input" {
            $r = $sampleObject | ConvertTo-JiraAttachment
            @($r).Count | Should Be 2
        }
    }
}
