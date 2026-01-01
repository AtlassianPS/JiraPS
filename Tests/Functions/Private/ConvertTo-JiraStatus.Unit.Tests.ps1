#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraStatus" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:statusName = 'In Progress'
            $script:statusId = 3
            $script:statusDesc = 'This issue is being actively worked on at the moment by the assignee.'

            $script:sampleJson = @"
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
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraStatus -InputObject $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.Status'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.Status'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraStatus -InputObject $sampleObject
                }

                It "defines 'Id' property with correct value" {
                    $result.Id | Should -Be $statusId
                }

                It "defines 'Name' property with correct value" {
                    $result.Name | Should -Be $statusName
                }

                It "defines 'Description' property with correct value" {
                    $result.Description | Should -Be $statusDesc
                }

                It "defines 'IconUrl' property with correct value" {
                    $result.IconUrl | Should -Be "$jiraServer/images/icons/statuses/inprogress.png"
                }

                It "defines 'RestUrl' property with correct value" {
                    $result.RestUrl | Should -Be "$jiraServer/rest/api/2/status/$statusId"
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraStatus -InputObject $sampleObject
                }

                It "converts Id to numeric type" {
                    $result.Id | Should -BeOfType ([System.ValueType])
                    $result.Id.GetType() | Should -BeIn @([int], [long], [int64])
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraStatus
                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
