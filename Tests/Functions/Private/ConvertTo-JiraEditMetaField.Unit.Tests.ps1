#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraEditMetaField" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
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
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions
        }

        Describe "Behavior" {
            BeforeAll {
                $script:result = ConvertTo-JiraEditMetaField -InputObject $sampleObject
            }

            Context "Object Conversion" {
                It "creates PSObject array from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                    $result | Should -BeOfType [PSCustomObject]
                    $result | Should -HaveCount 2
                }

                It "adds custom type 'JiraPS.EditMetaField' to each item" {
                    $result[0].PSObject.TypeNames[0] | Should -Be 'JiraPS.EditMetaField'
                    $result[1].PSObject.TypeNames[0] | Should -Be 'JiraPS.EditMetaField'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    # Our sample JSON includes two fields: summary and priority.
                    $script:summary = (ConvertTo-JiraEditMetaField -InputObject $sampleObject) | Where-Object -FilterScript { $_.Name -eq 'Summary' }
                    $script:priority = (ConvertTo-JiraEditMetaField -InputObject $sampleObject) | Where-Object -FilterScript { $_.Name -eq 'Priority' }
                }

                It "maps 'Id' property correctly" {
                    $summary.Id | Should -Be 'summary'
                }

                It "maps 'Name' property correctly" {
                    $summary.Name | Should -Be 'Summary'
                }

                It "maps 'HasDefaultValue' property correctly" {
                    $summary.HasDefaultValue | Should -Be $false
                    $priority.HasDefaultValue | Should -Be $true
                }

                It "maps 'Required' property correctly" {
                    $summary.Required | Should -Be $true
                    $priority.Required | Should -Be $false
                }

                It "maps 'Operations' property correctly" {
                    $summary.Operations | Should -Be @('set')
                    $priority.Operations | Should -Be @('set')
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:summary = (ConvertTo-JiraEditMetaField -InputObject $sampleObject) | Where-Object -FilterScript { $_.Name -eq 'Summary' }
                    $script:priority = (ConvertTo-JiraEditMetaField -InputObject $sampleObject) | Where-Object -FilterScript { $_.Name -eq 'Priority' }
                }

                It "includes 'Schema' property when available" {
                    $summary.Schema | Should -Not -BeNullOrEmpty
                    $priority.Schema | Should -Not -BeNullOrEmpty
                }

                It "includes 'AllowedValues' property when available" {
                    $summary.AllowedValues | Should -BeNullOrEmpty
                    $priority.AllowedValues | Should -Not -BeNullOrEmpty
                    $priority.AllowedValues.Count | Should -Be 5
                }
            }
        }

        Describe "Input Validation" {
            It "accepts positional parameters" {
                ConvertTo-JiraEditMetaField $sampleObject | Should -HaveCount 2
            }

            It "converts multiple attachments from array input" {
                ConvertTo-JiraEditMetaField -InputObject $sampleObject, $sampleObject | Should -HaveCount 4
            }

            It "accepts input from pipeline" {
                $sampleObject, $sampleObject | ConvertTo-JiraEditMetaField | Should -HaveCount 4
            }
        }
    }
}
