#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraCreateMetaField" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $sampleJson = @'
{
    "values": [
        {
            "required": true,
            "schema": {
                "type": "string",
                "system": "summary"
            },
            "name": "Summary",
            "fieldId": "summary",
            "hasDefaultValue": false,
            "operations": [
                "set"
            ]
        },
        {
            "required": false,
            "schema": {
                "type": "priority",
                "system": "priority"
            },
            "name": "Priority",
            "fieldId": "priority",
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
    ]
}
'@
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions
        }

        Describe "Behavior" {
            BeforeAll {
                $script:result = ConvertTo-JiraCreateMetaField -InputObject $sampleObject
            }

            Context "Object Conversion" {
                It "creates a PSObject out of JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                    $result | Should -BeOfType [PSCustomObject]
                    $result | Should -HaveCount 2
                }

                It "adds custom type 'JiraPS.CreateMetaField' to each item" {
                    $result[0].PSObject.TypeNames[0] | Should -Be 'JiraPS.CreateMetaField'
                    $result[1].PSObject.TypeNames[0] | Should -Be 'JiraPS.CreateMetaField'
                }
            }

            Context "Inputs" {
                It "converts multiple attachments from array input" {
                    ConvertTo-JiraCreateMetaField -InputObject $sampleObject, $sampleObject | Should -HaveCount 4
                }

                It "accepts input from pipeline" {
                    $sampleObject, $sampleObject | ConvertTo-JiraCreateMetaField | Should -HaveCount 4
                }
            }

            Context "Property Mapping" {
                # Our sample JSON includes two fields: summary and priority.
                Context "Example: Summary" {
                    BeforeAll {
                        $script:summary = (ConvertTo-JiraCreateMetaField -InputObject $sampleObject) | Where-Object -FilterScript { $_.Name -eq 'Summary' }
                    }

                    It "defines '<property>' of type '<type>' with value '<value>'" -TestCases @(
                        @{ property = "Id"; type = [string]; value = 'summary' }
                        @{ property = "Name"; type = [string]; value = 'Summary' }
                        @{ property = "HasDefaultValue"; type = [bool]; value = $false }
                        @{ property = "Required"; type = [bool]; value = $true }
                        @{ property = "Operations"; type = [string]; value = 'set' }
                        @{ property = "Schema"; type = [PSCustomObject]; value = $null }
                    ) {
                        if ($value) { $summary.$($property) | Should -Be $value }
                        else { $summary.$($property) | Should -Not -BeNullOrEmpty }

                        if ($type -is [string]) {
                            $summary.$($property).PSObject.TypeNames[0] | Should -Be $type
                        }
                        else { $summary.$($property) | Should -BeOfType $type }
                    }
                }
            }

            Context "Example: Priority" {
                BeforeAll {
                    $script:priority = (ConvertTo-JiraCreateMetaField -InputObject $sampleObject) | Where-Object -FilterScript { $_.Name -eq 'Priority' }
                }

                It "defines '<property>' of type '<type>' with value '<value>'" -TestCases @(
                    @{ property = "HasDefaultValue"; type = [bool]; value = $true }
                    @{ property = "Required"; type = [bool]; value = $false }
                    @{ property = "Operations"; type = [string]; value = 'set' }
                    @{ property = "Schema"; type = [PSCustomObject]; value = $null }
                    @{ property = "AllowedValues"; type = [PSCustomObject]; value = $null }
                ) {
                    if ($value) { $priority.$($property) | Should -Be $value }
                    else { $priority.$($property) | Should -Not -BeNullOrEmpty }

                    if ($type -is [string]) {
                        $priority.$($property).PSObject.TypeNames[0] | Should -Be $type
                    }
                    else { $priority.$($property) | Should -BeOfType $type }
                }
            }
        }
    }
}
