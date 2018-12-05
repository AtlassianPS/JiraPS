#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "ConvertTo-JiraIssueType" -Tag 'Unit' {

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

        $issueTypeId = 2
        $issueTypeName = 'Test Issue Type'
        $issueTypeDescription = 'A test issue used for...well, testing'

        $sampleJson = @"
{
    "self": "$jiraServer/rest/api/latest/issuetype/2",
    "id": "$issueTypeId",
    "description": "$issueTypeDescription",
    "iconUrl": "$jiraServer/images/icons/issuetypes/newfeature.png",
    "name": "$issueTypeName",
    "subtask": false
}
"@
        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        $r = ConvertTo-JiraIssueType $sampleObject
        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.IssueType'

        defProp $r 'Id' $issueTypeId
        defProp $r 'Name' $issueTypeName
        defProp $r 'Description' $issueTypeDescription
        defProp $r 'RestUrl' "$jiraServer/rest/api/latest/issuetype/$issueTypeId"
        defProp $r 'IconUrl' "$jiraServer/images/icons/issuetypes/newfeature.png"
        defProp $r 'Subtask' $false
    }
}
