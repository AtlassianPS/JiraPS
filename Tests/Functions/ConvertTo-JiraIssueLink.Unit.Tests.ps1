#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "ConvertTo-JiraIssueLink" -Tag 'Unit' {

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

        $issueLinkId = 41313
        $issueKeyInward = "TEST-01"
        $issueKeyOutward = "TEST-10"
        $linkTypeName = "Composition"

        $sampleJson = @"
{
    "id": "$issueLinkId",
    "type": {
        "id": "10500",
        "name": "$linkTypeName",
        "inward": "is part of",
        "outward": "composes"
    },
    "inwardIssue": {
        "key": "$issueKeyInward"
    },
    "outwardIssue": {
        "key": "$issueKeyOutward"
    }
}
"@

        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        $r = ConvertTo-JiraIssueLink -InputObject $sampleObject
        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.IssueLink'

        defProp $r 'Id' $issueLinkId
        defProp $r 'Type' "Composition"
        defProp $r 'InwardIssue' "[$issueKeyInward] "
        defProp $r 'OutwardIssue' "[$issueKeyOutward] "

        It "Handles pipeline input" {
            $r = $sampleObject | ConvertTo-JiraIssueLink
            @($r).Count | Should Be 1
        }
    }
}
