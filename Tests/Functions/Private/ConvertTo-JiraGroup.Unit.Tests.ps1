#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraGroup" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:groupName = 'powershell-testgroup'

            $script:sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/group?groupname=$groupName",
    "name": "$groupName",
    "users": {
        "size": 1,
        "items": [],
        "max-results": 50,
        "start-index": 0,
        "end-index": 0
    },
    "expand": "users"
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
                    $script:result = ConvertTo-JiraGroup -InputObject $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.Group'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.Group'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraGroup -InputObject $sampleObject
                }

                It "defines 'Name' property with correct value" {
                    $result.Name | Should -Be $groupName
                }

                It "defines 'RestUrl' property with correct value" {
                    $result.RestUrl | Should -Be "$jiraServer/rest/api/2/group?groupname=$groupName"
                }

                It "defines 'Size' property with correct value" {
                    $result.Size | Should -Be 1
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraGroup -InputObject $sampleObject
                }

                It "converts Size to numeric type" {
                    $result.Size | Should -BeOfType ([System.ValueType])
                    $result.Size.GetType() | Should -BeIn @([int], [long], [int64])
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraGroup
                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
