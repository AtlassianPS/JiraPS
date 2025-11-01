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
    Describe "ConvertTo-JiraPriority" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defProp / checkType / castsToString)

            $jiraServer = 'http://jiraserver.example.com'

            $priorityId = 1
            $priorityName = 'Critical'
            $priorityDescription = 'Cannot contine normal operations'

            $sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/priority/1",
    "statusColor": "#cc0000",
    "description": "$priorityDescription",
    "name": "$priorityName",
    "id": "$priorityId"
  }
"@
            $sampleObject = ConvertFrom-Json -InputObject $sampleJson
        }

        Context "Sanity checking" {
            BeforeAll {
                $r = ConvertTo-JiraPriority -InputObject $sampleObject
            }

            It "Creates a PSObject out of JSON input" {
                $r | Should -Not -BeNullOrEmpty
            }

            It "Uses correct output type" {
                checkType $r 'JiraPS.Priority'
            }

            It "Can cast to string" {
                castsToString $r
            }

            It "Defines expected properties" {
                defProp $r 'Id' $priorityId
                defProp $r 'Name' $priorityName
                defProp $r 'RestUrl' "$jiraServer/rest/api/2/priority/$priorityId"
                defProp $r 'Description' $priorityDescription
                defProp $r 'StatusColor' '#cc0000'
            }
        }
    }
}
