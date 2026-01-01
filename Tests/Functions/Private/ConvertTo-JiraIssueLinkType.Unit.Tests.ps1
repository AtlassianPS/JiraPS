#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraIssueLinkType" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'

            $script:sampleJson = @'
{
    "issueLinkTypes": [
        {
            "id": "10000",
            "name": "Blocks",
            "inward": "is blocked by",
            "outward": "blocks",
            "self": "http://jira.example.com/rest/api/2/issueLinkType/10000"
        },
        {
            "id": "10001",
            "name": "Cloners",
            "inward": "is cloned by",
            "outward": "clones",
            "self": "http://jira.example.com/rest/api/2/issueLinkType/10001"
        },
        {
            "id": "10002",
            "name": "Duplicate",
            "inward": "is duplicated by",
            "outward": "duplicates",
            "self": "http://jira.example.com/rest/api/2/issueLinkType/10002"
        },
        {
            "id": "10003",
            "name": "Relates",
            "inward": "relates to",
            "outward": "relates to",
            "self": "http://jira.example.com/rest/api/2/issueLinkType/10003"
        }
    ]
}
'@
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson | Select-Object -ExpandProperty issueLinkTypes
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Behavior" {
            BeforeAll {
                $script:result = ConvertTo-JiraIssueLinkType -InputObject $sampleObject[0]
            }

            Context "Object Conversion" {
                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.IssueLinkType'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.IssueLinkType'
                }
            }

            Context "Property Mapping" {
                It "defines 'Id' property with correct value" {
                    $result.Id | Should -Be '10000'
                }

                It "defines 'Name' property with correct value" {
                    $result.Name | Should -Be 'Blocks'
                }

                It "defines 'InwardText' property with correct value" {
                    $result.InwardText | Should -Be 'is blocked by'
                }

                It "defines 'OutwardText' property with correct value" {
                    $result.OutwardText | Should -Be 'blocks'
                }

                It "defines 'RestUrl' property with correct value" {
                    $result.RestUrl | Should -Be 'http://jira.example.com/rest/api/2/issueLinkType/10000'
                }
            }

            Context "Type Conversion" {
                It "converts Id to correct type" {
                    $result.Id | Should -BeOfType [string]
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $sampleObject | ConvertTo-JiraIssueLinkType | Should -HaveCount 4
                }

                It "provides array of objects if array is passed" {
                    $result = ConvertTo-JiraIssueLinkType -InputObject $sampleObject
                    $result[0].Id | Should -Be '10000'
                    $result[1].Id | Should -Be '10001'
                    $result[2].Id | Should -Be '10002'
                    $result[3].Id | Should -Be '10003'
                }
            }
        }
    }
}
