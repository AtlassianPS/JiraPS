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
    Describe "ConvertTo-JiraIssueLink" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defProp / checkPsType)

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
        }

        Context "Sanity checking" {
            It "Creates a PSObject out of JSON input" {
                $r = ConvertTo-JiraIssueLink -InputObject $sampleObject
                $r | Should -Not -BeNullOrEmpty
            }

            It "Uses correct output type" {
                $r = ConvertTo-JiraIssueLink -InputObject $sampleObject
                checkType $r "JiraPS.IssueLink"
            }

            It "Can cast to string" {
                $r = ConvertTo-JiraIssueLink -InputObject $sampleObject
                castsToString $r
            }

            It "Defines expected properties" {
                $r = ConvertTo-JiraIssueLink -InputObject $sampleObject
                defProp $r 'Id' $issueLinkId
                defProp $r 'Type' "Composition"
                defProp $r 'InwardIssue' "[$issueKeyInward] "
                defProp $r 'OutwardIssue' "[$issueKeyOutward] "
            }

            It "Handles pipeline input" {
                $r = $sampleObject | ConvertTo-JiraIssueLink
                @($r).Count | Should -Be 1
            }
        }
    }
}
