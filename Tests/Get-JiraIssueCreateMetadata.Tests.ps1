. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $restResult = ConvertFrom-Json2 @'
{
    "expand": "projects",
    "projects": [
        {
            "expand": "issuetypes",
            "self": "https://jira.example.com/rest/api/2/project/10003",
            "id": "10003",
            "key": "TEST",
            "name": "Test Project",
            "issuetypes": [
                {
                    "self": "https://jira.example.com/rest/api/latest/issuetype/2",
                    "id": "2",
                    "iconUrl": "https://jira.example.com/images/icons/issuetypes/newfeature.png",
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
                            "allowedValues": [
                                {
                                    "self": "https://jira.example.com/rest/api/2/issuetype/2",
                                    "id": "2",
                                    "description": "This is a test issue type",
                                    "iconUrl": "https://jira.example.com/images/icons/issuetypes/newfeature.png",
                                    "name": "Test Issue Type",
                                    "subtask": false
                                }
                            ]
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
                            "allowedValues": [
                                {
                                    "self": "https://jira.example.com/rest/api/2/project/10003",
                                    "id": "10003",
                                    "key": "TEST",
                                    "name": "Test Project",
                                    "projectCategory": {
                                        "self": "https://jira.example.com/rest/api/2/projectCategory/10000",
                                        "id": "10000",
                                        "description": "All Project Catagories",
                                        "name": "All Project"
                                    }
                                }
                            ]
                        },
                        "reporter": {
                            "required": true,
                            "schema": {
                                "type": "user",
                                "system": "reporter"
                            },
                            "name": "Reporter",
                            "autoCompleteUrl": "https://jira.example.com/rest/api/latest/user/search?username=",
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
                            "autoCompleteUrl": "https://jira.example.com/rest/api/latest/user/assignable/search?issueKey=null&username=",
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
                            "allowedValues": [
                                {
                                    "self": "https://jira.example.com/rest/api/2/priority/1",
                                    "iconUrl": "https://jira.example.com/images/icons/priorities/blocker.png",
                                    "name": "Blocker",
                                    "id": "1"
                                },
                                {
                                    "self": "https://jira.example.com/rest/api/2/priority/2",
                                    "iconUrl": "https://jira.example.com/images/icons/priorities/critical.png",
                                    "name": "Critical",
                                    "id": "2"
                                },
                                {
                                    "self": "https://jira.example.com/rest/api/2/priority/3",
                                    "iconUrl": "https://jira.example.com/images/icons/priorities/major.png",
                                    "name": "Major",
                                    "id": "3"
                                },
                                {
                                    "self": "https://jira.example.com/rest/api/2/priority/4",
                                    "iconUrl": "https://jira.example.com/images/icons/priorities/minor.png",
                                    "name": "Minor",
                                    "id": "4"
                                },
                                {
                                    "self": "https://jira.example.com/rest/api/2/priority/5",
                                    "iconUrl": "https://jira.example.com/images/icons/priorities/trivial.png",
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
                            "autoCompleteUrl": "https://jira.example.com/rest/api/1.0/labels/suggest?query=",
                            "hasDefaultValue": false,
                            "operations": [
                                "add",
                                "set",
                                "remove"
                            ]
                        }
                    }
                }
            ]
        }
    ]
}
'@

    Describe "Get-JiraIssueCreateMetadata" {

        Mock Get-JiraConfigServer {
            'https://jira.example.com'
        }

        Mock Get-JiraProject -ModuleName JiraPS {
            $object = [PSCustomObject] @{
                ID   = 10003
                Name = 'Test Project'
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
            return $object
        }

        Mock Get-JiraIssueType -ModuleName JiraPS {
            $object = [PSCustomObject] @{
                ID   = 2
                Name = 'Test Issue Type'
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.IssueType')
            return $object
        }

        Mock ConvertTo-JiraCreateMetaField -ModuleName JiraPS {
            $InputObject
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -like '*/rest/api/*/issue/createmeta?projectIds=10003&issuetypeIds=2&expand=projects.issuetypes.fields'
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            # @{ projects = @{ issuetypes = @{ fields = [PSCustomObject] @{ 'a' = 1 'b' = 2 } } } }
            ConvertFrom-Json $restResult
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraIssueCreateMetadata

            defParam $command 'Project'
            defParam $command 'IssueType'
            defParam $command 'Credential'
        }

        Context "Behavior testing" {

            It "Queries Jira for metadata information about creating an issue" {
                { Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Uses ConvertTo-JiraCreateMetaField to output CreateMetaField objects if JIRA returns data" {
                { Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It

                # There are 2 example fields in our mock above, but they should
                # be passed to Convert-JiraCreateMetaField as a single object.
                # The method should only be called once.
                Assert-MockCalled -CommandName ConvertTo-JiraCreateMetaField -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
        }
    }
}
