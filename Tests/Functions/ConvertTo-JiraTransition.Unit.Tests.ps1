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
    Describe "ConvertTo-JiraTransition" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defProp / checkType / castsToString)

            $jiraServer = 'http://jiraserver.example.com'

            $tId = 11
            $tName = 'Start Progress'

            # Transition result status
            $tRId = 3
            $tRName = 'In Progress'
            $tRDesc = 'This issue is being actively worked on at the moment by the assignee.'

            $sampleJson = @"
{
    "id": "$tId",
    "name": "$tName",
    "to": {
        "self": "$jiraServer/rest/api/2/status/$tRId",
        "description": "$tRDesc",
        "iconUrl": "$jiraServer/images/icons/statuses/inprogress.png",
        "name": "$tRName",
        "id": "$tRId",
        "statusCategory": {
            "self": "$jiraServer/rest/api/2/statuscategory/4",
            "id": 4,
            "key": "indeterminate",
            "colorName": "yellow",
            "name": "In Progress"
        }
    }
}
"@
            $sampleObject = ConvertFrom-Json -InputObject $sampleJson
        }

        Context "Sanity checking" {
            BeforeAll {
                $r = ConvertTo-JiraTransition -InputObject $sampleObject
            }

            It "Creates a PSObject out of JSON input" {
                $r | Should -Not -BeNullOrEmpty
            }

            It "Uses correct output type" {
                checkType $r 'JiraPS.Transition'
            }

            It "Can cast to string" {
                castsToString $r
            }

            It "Defines expected properties" {
                defProp $r 'Id' $tId
                defProp $r 'Name' $tName
            }

            It "Defines the 'ResultStatus' property as a JiraPS.Status object" {
                $r.ResultStatus.Id | Should -Be $tRId
                $r.ResultStatus.Name | Should -Be $tRName
            }
        }
    }
}
