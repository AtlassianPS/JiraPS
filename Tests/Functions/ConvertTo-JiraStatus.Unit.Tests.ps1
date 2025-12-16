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

InModuleScope JiraPS {
    Describe "ConvertTo-JiraStatus" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defProp / checkType / castsToString)

            $jiraServer = 'http://jiraserver.example.com'

            $statusName = 'In Progress'
            $statusId = 3
            $statusDesc = 'This issue is being actively worked on at the moment by the assignee.'

            $sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/status/$statusId",
    "description": "$statusDesc",
    "iconUrl": "$jiraServer/images/icons/statuses/inprogress.png",
    "name": "$statusName",
    "id": "$statusId",
    "statusCategory": {
        "self": "$jiraServer/rest/api/2/statuscategory/4",
        "id": 4,
        "key": "indeterminate",
        "colorName": "yellow",
        "name": "In Progress"
    }
}
"@
            $sampleObject = ConvertFrom-Json -InputObject $sampleJson
        }

        Context "Sanity checking" {
            BeforeAll {
                $r = ConvertTo-JiraStatus -InputObject $sampleObject
            }

            It "Creates a PSObject out of JSON input" {
                $r | Should -Not -BeNullOrEmpty
            }

            It "Uses correct output type" {
                checkType $r 'JiraPS.Status'
            }

            It "Can cast to string" {
                castsToString $r
            }

            It "Defines expected properties" {
                defProp $r 'Id' $statusId
                defProp $r 'Name' $statusName
                defProp $r 'Description' $statusDesc
                defProp $r 'IconUrl' "$jiraServer/images/icons/statuses/inprogress.png"
                defProp $r 'RestUrl' "$jiraServer/rest/api/2/status/$statusId"
            }
        }
    }
}
