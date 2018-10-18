#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "ConvertTo-JiraIssueLinkType" -Tag 'Unit' {

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

        $sampleJson = @'
{
    "issueLinkTypes": [
        {
            "id": "10000",
            "name": "Blocks",
            "inward": "is blocked by",
            "outward": "blocks",
            "self": "http://jira.example.com/rest/api/latest/issueLinkType/10000"
        },
        {
            "id": "10001",
            "name": "Cloners",
            "inward": "is cloned by",
            "outward": "clones",
            "self": "http://jira.example.com/rest/api/latest/issueLinkType/10001"
        },
        {
            "id": "10002",
            "name": "Duplicate",
            "inward": "is duplicated by",
            "outward": "duplicates",
            "self": "http://jira.example.com/rest/api/latest/issueLinkType/10002"
        },
        {
            "id": "10003",
            "name": "Relates",
            "inward": "relates to",
            "outward": "relates to",
            "self": "http://jira.example.com/rest/api/latest/issueLinkType/10003"
        }
    ]
}
'@

        $sampleObject = ConvertFrom-Json -InputObject $sampleJson | Select-Object -ExpandProperty issueLinkTypes

        $r = ConvertTo-JiraIssueLinkType -InputObject $sampleObject[0]
        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.IssueLinkType'

        defProp $r 'Id' '10000'
        defProp $r 'Name' 'Blocks'
        defProp $r 'InwardText' 'is blocked by'
        defProp $r 'OutwardText' 'blocks'
        defProp $r 'RestUrl' 'http://jira.example.com/rest/api/latest/issueLinkType/10000'

        It "Provides an array of objects if an array is passed" {
            $r2 = ConvertTo-JiraIssueLinkType -InputObject $sampleObject
            $r2.Count | Should Be 4
            $r2[0].Id | Should Be '10000'
            $r2[1].Id | Should Be '10001'
            $r2[2].Id | Should Be '10002'
            $r2[3].Id | Should Be '10003'
        }

        It "Handles pipeline input" {
            $r = $sampleObject | ConvertTo-JiraIssueLinkType
            $r.Count | Should Be 4
        }
    }
}
