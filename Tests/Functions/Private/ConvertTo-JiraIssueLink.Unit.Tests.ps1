#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraIssueLink" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueLinkId = 41313
            $script:issueKeyInward = "TEST-01"
            $script:issueKeyOutward = "TEST-10"
            $script:linkTypeName = "Composition"

            $script:sampleJson = @"
{
    "id": "$issueLinkId",
    "type": {
        "id": "10500",
        "name": "$linkTypeName",
        "inward": "is part of",
        "outward": "composes"
    },
    "inwardIssue": {
        "key": "$issueKeyInward"
    },
    "outwardIssue": {
        "key": "$issueKeyOutward"
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
                    $script:result = ConvertTo-JiraIssueLink -InputObject $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.IssueLink'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.IssueLink'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraIssueLink -InputObject $sampleObject
                }

                It "defines 'Id' property with correct value" {
                    $result.Id | Should -Be $issueLinkId
                }

                It "defines 'Type' property with correct value" {
                    $result.Type | Should -Be "Composition"
                }

                It "defines 'InwardIssue' property with correct value" {
                    $result.InwardIssue | Should -Be "[$issueKeyInward] "
                }

                It "defines 'OutwardIssue' property with correct value" {
                    $result.OutwardIssue | Should -Be "[$issueKeyOutward] "
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraIssueLink -InputObject $sampleObject
                }

                It "converts Id to numeric type" {
                    $result.Id | Should -BeOfType ([System.ValueType])
                    $result.Id.GetType() | Should -BeIn @([int], [long], [int64])
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraIssueLink

                    $result | Should -HaveCount 1
                }
            }
        }
    }
}
