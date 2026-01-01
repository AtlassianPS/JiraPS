#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraPriority" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:priorityId = 1
            $script:priorityName = 'Critical'
            $script:priorityDescription = 'Cannot contine normal operations'

            $script:sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/priority/1",
    "statusColor": "#cc0000",
    "description": "$priorityDescription",
    "name": "$priorityName",
    "id": "$priorityId"
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
                    $script:result = ConvertTo-JiraPriority -InputObject $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.Priority'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.Priority'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraPriority -InputObject $sampleObject
                }

                It "defines 'Id' property with correct value" {
                    $result.Id | Should -Be $priorityId
                }

                It "defines 'Name' property with correct value" {
                    $result.Name | Should -Be $priorityName
                }

                It "defines 'RestUrl' property with correct value" {
                    $result.RestUrl | Should -Be "$jiraServer/rest/api/2/priority/$priorityId"
                }

                It "defines 'Description' property with correct value" {
                    $result.Description | Should -Be $priorityDescription
                }

                It "defines 'StatusColor' property with correct value" {
                    $result.StatusColor | Should -Be '#cc0000'
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraPriority -InputObject $sampleObject
                }

                It "converts Id to numeric type" {
                    $result.Id | Should -BeOfType ([System.ValueType])
                    $result.Id.GetType() | Should -BeIn @([int], [long], [int64])
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraPriority
                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
