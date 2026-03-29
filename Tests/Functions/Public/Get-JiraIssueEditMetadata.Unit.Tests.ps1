#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraIssueEditMetadata" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = "https://jira.example.com"
            $script:issueID = 41701
            $script:issueKey = 'IT-3676'

            $script:restResult = @"
{
    "fields": {
        "summary": {
            "required": true,
            "schema": {
                "type": "string",
                "system": "summary"
            },
            "name": "Summary",
            "hasDefaultValue": false,
            "operations": [
                "set"
            ]
        },
        "issuetype": {
            "required": true,
            "schema": {
                "type": "issuetype",
                "system": "issuetype"
            },
            "name": "Issue Type",
            "hasDefaultValue": false,
            "operations": [],
            "allowedValues": [{
                "self": "$jiraServer/rest/api/2/issuetype/2",
                "id": "2",
                "description": "This is a test issue type",
                "iconUrl": "$jiraServer/images/icons/issuetypes/newfeature.png",
                "name": "Test Issue Type",
                "subtask": false
            }]
        },
        "description": {
            "required": false,
            "schema": {
                "type": "string",
                "system": "description"
            },
            "name": "Description",
            "hasDefaultValue": false,
            "operations": [
                "set"
            ]
        },
        "project": {
            "required": true,
            "schema": {
                "type": "project",
                "system": "project"
            },
            "name": "Project",
            "hasDefaultValue": false,
            "operations": [
                "set"
            ],
            "allowedValues": [{
                "self": "$jiraServer/rest/api/2/project/10003",
                "id": "10003",
                "key": "TEST",
                "name": "Test Project",
                "projectCategory": {
                    "self": "$jiraServer/rest/api/2/projectCategory/10000",
                    "id": "10000",
                    "description": "All Project Catagories",
                    "name": "All Project"
                }
            }]
        },
        "reporter": {
            "required": true,
            "schema": {
                "type": "user",
                "system": "reporter"
            },
            "name": "Reporter",
            "autoCompleteUrl": "$jiraServer/rest/api/2/user/search?username=",
            "hasDefaultValue": false,
            "operations": [
                "set"
            ]
        },
        "assignee": {
            "required": false,
            "schema": {
                "type": "user",
                "system": "assignee"
            },
            "name": "Assignee",
            "autoCompleteUrl": "$jiraServer/rest/api/2/user/assignable/search?issueKey=null&username=",
            "hasDefaultValue": false,
            "operations": [
                "set"
            ]
        },
        "priority": {
            "required": false,
            "schema": {
                "type": "priority",
                "system": "priority"
            },
            "name": "Priority",
            "hasDefaultValue": true,
            "operations": [
                "set"
            ],
            "allowedValues": [{
                    "self": "$jiraServer/rest/api/2/priority/1",
                    "iconUrl": "$jiraServer/images/icons/priorities/blocker.png",
                    "name": "Blocker",
                    "id": "1"
                },
                {
                    "self": "$jiraServer/rest/api/2/priority/2",
                    "iconUrl": "$jiraServer/images/icons/priorities/critical.png",
                    "name": "Critical",
                    "id": "2"
                },
                {
                    "self": "$jiraServer/rest/api/2/priority/3",
                    "iconUrl": "$jiraServer/images/icons/priorities/major.png",
                    "name": "Major",
                    "id": "3"
                },
                {
                    "self": "$jiraServer/rest/api/2/priority/4",
                    "iconUrl": "$jiraServer/images/icons/priorities/minor.png",
                    "name": "Minor",
                    "id": "4"
                },
                {
                    "self": "$jiraServer/rest/api/2/priority/5",
                    "iconUrl": "$jiraServer/images/icons/priorities/trivial.png",
                    "name": "Trivial",
                    "id": "5"
                }
            ]
        },
        "labels": {
            "required": false,
            "schema": {
                "type": "array",
                "items": "string",
                "system": "labels"
            },
            "name": "Labels",
            "autoCompleteUrl": "$jiraServer/rest/api/1.0/labels/suggest?query=",
            "hasDefaultValue": false,
            "operations": [
                "add",
                "set",
                "remove"
            ]
        }
    }
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                [PSCustomObject] @{
                    ID      = $issueID
                    Key     = $issueKey
                    RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
                }
            }

            Mock ConvertTo-JiraEditMetaField -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraEditMetaField' 'InputObject'
                $InputObject
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "*/rest/api/*/issue/$issueID/editmeta" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResult
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            Context "Parameter Types" {
                # TODO: Add parameter type validation tests
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Behavior testing" {
                It "Queries Jira for metadata information about editing an issue" {
                    { Get-JiraIssueEditMetadata -Issue $issueID } | Should -Not -Throw
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "Uses ConvertTo-JiraEditMetaField to output EditMetaField objects if JIRA returns data" {
                    { Get-JiraIssueEditMetadata -Issue $issueID } | Should -Not -Throw
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It

                    # There are 2 example fields in our mock above, but they should
                    # be passed to Convert-JiraCreateMetaField as a single object.
                    # The method should only be called once.
                    Should -Invoke ConvertTo-JiraEditMetaField -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
