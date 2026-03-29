#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraFilterPermission" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:sampleJson = @'
[
  {
    "id": 10000,
    "type": "global"
  },
  {
    "id": 10010,
    "type": "project",
    "project": {
      "self": "$jiraServer/jira/rest/api/2/project/EX",
      "id": "10000",
      "key": "EX",
      "name": "Example",
      "avatarUrls": {
        "48x48": "$jiraServer/jira/secure/projectavatar?size=large&pid=10000",
        "24x24": "$jiraServer/jira/secure/projectavatar?size=small&pid=10000",
        "16x16": "$jiraServer/jira/secure/projectavatar?size=xsmall&pid=10000",
        "32x32": "$jiraServer/jira/secure/projectavatar?size=medium&pid=10000"
      },
      "projectCategory": {
        "self": "$jiraServer/jira/rest/api/2/projectCategory/10000",
        "id": "10000",
        "name": "FIRST",
        "description": "First Project Category"
      },
      "simplified": false
    }
  },
  {
    "id": 10010,
    "type": "project",
    "project": {
      "self": "$jiraServer/jira/rest/api/2/project/MKY",
      "id": "10002",
      "key": "MKY",
      "name": "Example",
      "avatarUrls": {
        "48x48": "$jiraServer/jira/secure/projectavatar?size=large&pid=10002",
        "24x24": "$jiraServer/jira/secure/projectavatar?size=small&pid=10002",
        "16x16": "$jiraServer/jira/secure/projectavatar?size=xsmall&pid=10002",
        "32x32": "$jiraServer/jira/secure/projectavatar?size=medium&pid=10002"
      },
      "projectCategory": {
        "self": "$jiraServer/jira/rest/api/2/projectCategory/10000",
        "id": "10000",
        "name": "FIRST",
        "description": "First Project Category"
      },
      "simplified": false
    },
    "role": {
      "self": "$jiraServer/jira/rest/api/2/project/MKY/role/10360",
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
  },
  {
    "id": 10010,
    "type": "group",
    "group": {
      "name": "jira-administrators",
      "self": "$jiraServer/jira/rest/api/2/group?groupname=jira-administrators"
    }
  }
]
'@
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraFilterPermission -InputObject $sampleObject
                }

                It "creates PSObject array from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                    $result | Should -HaveCount 4
                }

                It "adds custom type 'JiraPS.FilterPermission' to each item" {
                    $result[0].PSObject.TypeNames[0] | Should -Be 'JiraPS.FilterPermission'
                    $result[1].PSObject.TypeNames[0] | Should -Be 'JiraPS.FilterPermission'
                    $result[2].PSObject.TypeNames[0] | Should -Be 'JiraPS.FilterPermission'
                    $result[3].PSObject.TypeNames[0] | Should -Be 'JiraPS.FilterPermission'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraFilterPermission -InputObject $sampleObject
                }

                It "maps 'Id' property correctly" {
                    $result[0].Id | Should -Be 10000
                    $result[1].Id | Should -Be 10010
                    $result[2].Id | Should -Be 10010
                    $result[3].Id | Should -Be 10010
                }

                It "maps 'Type' property correctly" {
                    $result[0].Type | Should -Be 'global'
                    $result[1].Type | Should -Be 'project'
                    $result[2].Type | Should -Be 'project'
                    $result[3].Type | Should -Be 'group'
                }

                It "maps 'Project' property when available" {
                    $result[0].Project | Should -BeNullOrEmpty
                    $result[1].Project | Should -Not -BeNullOrEmpty
                    $result[1].Project.Name | Should -Be 'Example'
                    $result[2].Project | Should -Not -BeNullOrEmpty
                    $result[2].Project.Name | Should -Be 'Example'
                }

                It "maps 'Role' property when available" {
                    $result[2].Role | Should -Not -BeNullOrEmpty
                    $result[2].Role.Name | Should -Be 'Developers'
                }

                It "maps 'Group' property when available" {
                    $result[3].Group | Should -Not -BeNullOrEmpty
                    $result[3].Group.Name | Should -Be 'jira-administrators'
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraFilterPermission -InputObject $sampleObject
                }

                It "converts nested Project to 'JiraPS.Project' type" {
                    $result[1].Project.PSObject.TypeNames[0] | Should -Be 'JiraPS.Project'
                }

                It "converts nested Role to 'JiraPS.ProjectRole' type" {
                    $result[2].Role.PSObject.TypeNames[0] | Should -Be 'JiraPS.ProjectRole'
                }

                It "converts nested Group to 'JiraPS.Group' type" {
                    $result[3].Group.PSObject.TypeNames[0] | Should -Be 'JiraPS.Group'
                }

                It "converts Id to numeric type" {
                    $result[0].Id | Should -BeOfType [ValueType]
                    $result[0].Id.GetType().Name | Should -Match '^(Int32|Int64)$'
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    { $sampleObject | ConvertTo-JiraFilterPermission } | Should -Not -Throw
                }

                It "processes array of permissions from pipeline" {
                    $result = @($sampleObject, $sampleObject) | ConvertTo-JiraFilterPermission
                    $result | Should -HaveCount 8
                }
            }
        }
    }
}
