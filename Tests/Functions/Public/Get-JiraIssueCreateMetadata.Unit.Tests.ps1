#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraIssueCreateMetadata" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'https://jira.example.com'

            $script:restResult = @"
{
    "expand": "projects",
    "projects": [{
        "expand": "issuetypes",
        "self": "$jiraserver/rest/api/2/project/10003",
        "id": "10003",
        "key": "TEST",
        "name": "Test Project",
        "issuetypes": [{
            "self": "$jiraserver/rest/api/2/issuetype/2",
            "id": "2",
            "iconUrl": "$jiraserver/images/icons/issuetypes/newfeature.png",
            "name": "Test Issue Type",
            "subtask": false,
            "expand": "fields",
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
                        "self": "$jiraserver/rest/api/2/issuetype/2",
                        "id": "2",
                        "description": "This is a test issue type",
                        "iconUrl": "$jiraserver/images/icons/issuetypes/newfeature.png",
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
                        "self": "$jiraserver/rest/api/2/project/10003",
                        "id": "10003",
                        "key": "TEST",
                        "name": "Test Project",
                        "projectCategory": {
                            "self": "$jiraserver/rest/api/2/projectCategory/10000",
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
                    "autoCompleteUrl": "$jiraserver/rest/api/2/user/search?username=",
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
                    "autoCompleteUrl": "$jiraserver/rest/api/2/user/assignable/search?issueKey=null&username=",
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
                            "self": "$jiraserver/rest/api/2/priority/1",
                            "iconUrl": "$jiraserver/images/icons/priorities/blocker.png",
                            "name": "Blocker",
                            "id": "1"
                        },
                        {
                            "self": "$jiraserver/rest/api/2/priority/2",
                            "iconUrl": "$jiraserver/images/icons/priorities/critical.png",
                            "name": "Critical",
                            "id": "2"
                        },
                        {
                            "self": "$jiraserver/rest/api/2/priority/3",
                            "iconUrl": "$jiraserver/images/icons/priorities/major.png",
                            "name": "Major",
                            "id": "3"
                        },
                        {
                            "self": "$jiraserver/rest/api/2/priority/4",
                            "iconUrl": "$jiraserver/images/icons/priorities/minor.png",
                            "name": "Minor",
                            "id": "4"
                        },
                        {
                            "self": "$jiraserver/rest/api/2/priority/5",
                            "iconUrl": "$jiraserver/images/icons/priorities/trivial.png",
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
                    "autoCompleteUrl": "$jiraserver/rest/api/1.0/labels/suggest?query=",
                    "hasDefaultValue": false,
                    "operations": [
                        "add",
                        "set",
                        "remove"
                    ]
                }
            }
        }]
    }]
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraserver
            }

            Mock Get-JiraProject -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraProject'
                $issueObject = [PSCustomObject] @{
                    ID   = 2
                    Name = 'Test Issue Type'
                }
                $issueObject.PSObject.TypeNames.Insert(0, 'JiraPS.IssueType')
                $object = [PSCustomObject] @{
                    ID   = 10003
                    Name = 'Test Project'
                }
                Add-Member -InputObject $object -MemberType NoteProperty -Name "IssueTypes" -Value $issueObject
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
                return $object
            }

            Mock ConvertTo-JiraCreateMetaField -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraCreateMetaField' 'InputObject'
                $InputObject
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraserver/rest/api/*/issue/createmeta?*" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                return $restResult
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
                It "Queries Jira for metadata information about creating an issue" {
                    { Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2 } | Should -Not -Throw
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "Uses ConvertTo-JiraCreateMetaField to output CreateMetaField objects if JIRA returns data" {
                    { Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2 } | Should -Not -Throw
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It

                    # There are 2 example fields in our mock above, but they should
                    # be passed to Convert-JiraCreateMetaField as a single object.
                    # The method should only be called once.
                    Should -Invoke ConvertTo-JiraCreateMetaField -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
