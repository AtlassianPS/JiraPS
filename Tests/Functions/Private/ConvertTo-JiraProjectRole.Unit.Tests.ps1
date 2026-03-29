#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraProjectRole" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:sampleJson = @"
[
  {
    "self": "http://www.example.com/jira/rest/api/2/project/MKY/role/10360",
    "name": "Developers",
    "id": 10360,
    "description": "A project role that represents developers in a project",
    "actors": [
      {
        "id": 10240,
        "displayName": "jira-developers",
        "type": "atlassian-group-role-actor",
        "name": "jira-developers"
      },
      {
        "id": 10241,
        "displayName": "Fred F. User",
        "type": "atlassian-user-role-actor",
        "name": "fred"
      }
    ]
  }
]
"@
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraProjectRole -InputObject $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.ProjectRole'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.ProjectRole'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraProjectRole -InputObject $sampleObject
                }

                It "defines 'Id' property with correct value" {
                    $result.Id | Should -Be 10360
                }

                It "defines 'Name' property with correct value" {
                    $result.Name | Should -Be "Developers"
                }

                It "defines 'Description' property with correct value" {
                    $result.Description | Should -Be "A project role that represents developers in a project"
                }

                It "defines 'Actors' property" {
                    $result.Actors | Should -Not -BeNullOrEmpty
                }

                It "defines 'RestUrl' property with correct value" {
                    $result.RestUrl | Should -Be "http://www.example.com/jira/rest/api/2/project/MKY/role/10360"
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraProjectRole -InputObject $sampleObject
                }

                It "converts Id to numeric type" {
                    $result.Id | Should -BeOfType ([System.ValueType])
                    $result.Id.GetType() | Should -BeIn @([int], [long], [int64])
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraProjectRole
                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
