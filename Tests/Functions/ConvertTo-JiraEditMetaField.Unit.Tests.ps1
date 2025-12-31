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
    Describe "ConvertTo-JiraEditMetaField" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defProp / checkType / castsToString)

        $sampleJson = @'
{
    "fields": {
        "summary": {
            "required": true,
            "schema": {
                "type": "string",
                "system": "summary"
            },
            "name": "Summary",
            "hasDefaultValue": false,
            "operations": [
                "set"
            ]
        },
        "priority": {
            "required": false,
            "schema": {
                "type": "priority",
                "system": "priority"
            },
            "name": "Priority",
            "hasDefaultValue": true,
            "operations": [
                "set"
            ],
            "allowedValues": [
                {
                    "self": "http://jiraserver.example.com/rest/api/2/priority/1",
                    "iconUrl": "http://jiraserver.example.com/images/icons/priorities/blocker.png",
                    "name": "Block",
                    "id": "1"
                },
                {
                    "self": "http://jiraserver.example.com/rest/api/2/priority/2",
                    "iconUrl": "http://jiraserver.example.com/images/icons/priorities/critical.png",
                    "name": "Critical",
                    "id": "2"
                },
                {
                    "self": "http://jiraserver.example.com/rest/api/2/priority/3",
                    "iconUrl": "http://jiraserver.example.com/images/icons/priorities/major.png",
                    "name": "Major",
                    "id": "3"
                },
                {
                    "self": "http://jiraserver.example.com/rest/api/2/priority/4",
                    "iconUrl": "http://jiraserver.example.com/images/icons/priorities/minor.png",
                    "name": "Minor",
                    "id": "4"
                },
                {
                    "self": "http://jiraserver.example.com/rest/api/2/priority/5",
                    "iconUrl": "http://jiraserver.example.com/images/icons/priorities/trivial.png",
                    "name": "Trivial",
                    "id": "5"
                }
            ]
        }
    }
}
'@
        $sampleObject = ConvertFrom-Json -InputObject $sampleJson
    }

        Context "Sanity checking" {
            BeforeAll {
                $r = ConvertTo-JiraEditMetaField $sampleObject
            }

            It "Creates PSObjects out of JSON input" {
                $r | Should -Not -BeNullOrEmpty
                $r.Count | Should -Be 2
            }

            It "Uses correct output type" {
                checkType $r[0] 'JiraPS.EditMetaField'
            }

            It "Can cast to string" {
                castsToString $r[0]
            }
        }

        Context "Data validation" {
            It "Defines expected properties for summary field" {
                # Our sample JSON includes two fields: summary and priority.
                $summary = ConvertTo-JiraEditMetaField $sampleObject | Where-Object -FilterScript {$_.Name -eq 'Summary'}
                defProp $summary 'Id' 'summary'
                defProp $summary 'Name' 'Summary'
                defProp $summary 'HasDefaultValue' $false
                defProp $summary 'Required' $true
                defProp $summary 'Operations' @('set')
            }

            It "Defines the 'Schema' property if available" {
                $summary = ConvertTo-JiraEditMetaField $sampleObject | Where-Object -FilterScript {$_.Name -eq 'Summary'}
                $priority = ConvertTo-JiraEditMetaField $sampleObject | Where-Object -FilterScript {$_.Name -eq 'Priority'}
                $summary.Schema | Should -Not -BeNullOrEmpty
                $priority.Schema | Should -Not -BeNullOrEmpty
            }

            It "Defines the 'AllowedValues' property if available" {
                $summary = ConvertTo-JiraEditMetaField $sampleObject | Where-Object -FilterScript {$_.Name -eq 'Summary'}
                $priority = ConvertTo-JiraEditMetaField $sampleObject | Where-Object -FilterScript {$_.Name -eq 'Priority'}
                $summary.AllowedValues | Should -BeNullOrEmpty
                $priority.AllowedValues | Should -Not -BeNullOrEmpty
            }
        }
    }
}
