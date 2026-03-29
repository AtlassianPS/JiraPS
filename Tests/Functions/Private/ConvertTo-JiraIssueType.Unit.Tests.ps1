#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraIssueType" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueTypeId = 2
            $script:issueTypeName = 'Test Issue Type'
            $script:issueTypeDescription = 'A test issue used for...well, testing'

            $script:sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/issuetype/2",
    "id": "$issueTypeId",
    "description": "$issueTypeDescription",
    "iconUrl": "$jiraServer/images/icons/issuetypes/newfeature.png",
    "name": "$issueTypeName",
    "subtask": false
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
                    $script:result = ConvertTo-JiraIssueType $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.IssueType'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.IssueType'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraIssueType $sampleObject
                }

                It "defines 'Id' property with correct value" {
                    $result.Id | Should -Be $issueTypeId
                }

                It "defines 'Name' property with correct value" {
                    $result.Name | Should -Be $issueTypeName
                }

                It "defines 'Description' property with correct value" {
                    $result.Description | Should -Be $issueTypeDescription
                }

                It "defines 'RestUrl' property with correct value" {
                    $result.RestUrl | Should -Be "$jiraServer/rest/api/2/issuetype/$issueTypeId"
                }

                It "defines 'IconUrl' property with correct value" {
                    $result.IconUrl | Should -Be "$jiraServer/images/icons/issuetypes/newfeature.png"
                }

                It "defines 'Subtask' property with correct value" {
                    $result.Subtask | Should -Be $false
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraIssueType $sampleObject
                }

                It "converts Id to numeric type" {
                    $result.Id | Should -BeOfType ([System.ValueType])
                    $result.Id.GetType() | Should -BeIn @([int], [long], [int64])
                }

                It "converts Subtask to correct type" {
                    $result.Subtask | Should -BeOfType [bool]
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraIssueType
                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
