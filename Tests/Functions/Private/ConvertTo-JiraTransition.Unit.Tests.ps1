#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraTransition" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:tId = 11
            $script:tName = 'Start Progress'

            # Transition result status
            $script:tRId = 3
            $script:tRName = 'In Progress'
            $script:tRDesc = 'This issue is being actively worked on at the moment by the assignee.'

            $script:sampleJson = @"
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
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraTransition -InputObject $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.Transition'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.Transition'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraTransition -InputObject $sampleObject
                }

                It "defines 'Id' property with correct value" {
                    $result.Id | Should -Be $tId
                }

                It "defines 'Name' property with correct value" {
                    $result.Name | Should -Be $tName
                }

                It "defines 'ResultStatus' property as JiraPS.Status object" {
                    $result.ResultStatus.Id | Should -Be $tRId
                    $result.ResultStatus.Name | Should -Be $tRName
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraTransition -InputObject $sampleObject
                }

                It "converts Id to numeric type" {
                    $result.Id | Should -BeOfType ([System.ValueType])
                    $result.Id.GetType() | Should -BeIn @([int], [long], [int64])
                }

                It "converts ResultStatus to JiraPS.Status type" {
                    $result.ResultStatus.PSObject.TypeNames[0] | Should -Be 'JiraPS.Status'
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraTransition
                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
