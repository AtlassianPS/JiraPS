$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $jiraServer = 'http://jiraserver.example.com'
    $issueID = 41701
    $issueKey = 'IT-3676'

    $projectID = 10003
    $projectName = 'Test Project'

    $issueTypeID = 2
    $issueTypeName = 'Test Issue Type'

    $restResult = @"
{
  "expand": "projects",
  "projects": [
    {
      "expand": "issuetypes",
      "self": "$jiraServer/rest/api/2/project/10003",
      "id": "$projectId",
      "key": "IT",
      "name": "$projectName",
      "issuetypes": [
        {
          "self": "$jiraServer/rest/api/latest/issuetype/2",
          "id": "$issueTypeID",
          "description": "An issue related to end-user workstations.",
          "name": "$issueTypeName",
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
                  "self": "$jiraServer/rest/api/2/issuetype/2",
                  "id": "$issueTypeID",
                  "description": "An issue related to end-user workstations.",
                  "iconUrl": "$jiraServer/images/icons/issuetypes/newfeature.png",
                  "name": "$issueTypeName",
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
                  "self": "$jiraServer/rest/api/2/project/$projectId",
                  "id": "$projectId",
                  "key": "IT",
                  "name": "$projectName",
                  "projectCategory": {
                    "self": "$jiraServer/rest/api/2/projectCategory/10000",
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
              "autoCompleteUrl": "$jiraServer/rest/api/latest/user/search?username=",
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
              "autoCompleteUrl": "$jiraServer/rest/api/latest/user/assignable/search?issueKey=null&username=",
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
                  "self": "$jiraServer/rest/api/2/priority/1",
                  "iconUrl": "$jiraServer/images/icons/priorities/blocker.png",
                  "name": "Critical",
                  "id": "1"
                },
                {
                  "self": "$jiraServer/rest/api/2/priority/2",
                  "iconUrl": "$jiraServer/images/icons/priorities/critical.png",
                  "name": "High",
                  "id": "2"
                },
                {
                  "self": "$jiraServer/rest/api/2/priority/3",
                  "iconUrl": "$jiraServer/images/icons/priorities/major.png",
                  "name": "Normal",
                  "id": "3"
                },
                {
                  "self": "$jiraServer/rest/api/2/priority/4",
                  "iconUrl": "$jiraServer/images/icons/priorities/minor.png",
                  "name": "Project",
                  "id": "4"
                },
                {
                  "self": "$jiraServer/rest/api/2/priority/5",
                  "iconUrl": "$jiraServer/images/icons/priorities/trivial.png",
                  "name": "Low",
                  "id": "5"
                }
              ]
            },
            "customfield_10001": {
              "required": false,
              "schema": {
                "type": "datetime",
                "custom": "com.atlassian.jira.plugin.system.customfieldtypes:datetime",
                "customId": 10001
              },
              "name": "Requested Completion Date",
              "hasDefaultValue": false,
              "operations": [
                "set"
              ]
            },
            "customfield_10012": {
              "required": true,
              "schema": {
                "type": "string",
                "custom": "com.atlassian.jira.plugin.system.customfieldtypes:textfield",
                "customId": 10012
              },
              "name": "Contact Phone",
              "hasDefaultValue": false,
              "operations": [
                "set"
              ]
            },
            "customfield_10002": {
              "required": true,
              "schema": {
                "type": "string",
                "custom": "com.atlassian.jira.plugin.system.customfieldtypes:textfield",
                "customId": 10002
              },
              "name": "Issue Location",
              "hasDefaultValue": false,
              "operations": [
                "set"
              ]
            },
            "customfield_10014": {
              "required": false,
              "schema": {
                "type": "string",
                "custom": "com.atlassian.jira.plugin.system.customfieldtypes:select",
                "customId": 10014
              },
              "name": "Hardware Type",
              "hasDefaultValue": false,
              "operations": [
                "set"
              ],
              "allowedValues": [
                {
                  "self": "$jiraServer/rest/api/2/customFieldOption/10017",
                  "value": "PC",
                  "id": "10017"
                },
                {
                  "self": "$jiraServer/rest/api/2/customFieldOption/10018",
                  "value": "MAC",
                  "id": "10018"
                },
                {
                  "self": "$jiraServer/rest/api/2/customFieldOption/10080",
                  "value": "Cell Phone",
                  "id": "10080"
                },
                {
                  "self": "$jiraServer/rest/api/2/customFieldOption/10019",
                  "value": "Monitor",
                  "id": "10019"
                },
                {
                  "self": "$jiraServer/rest/api/2/customFieldOption/10020",
                  "value": "Printer",
                  "id": "10020"
                },
                {
                  "self": "$jiraServer/rest/api/2/customFieldOption/10021",
                  "value": "Copier",
                  "id": "10021"
                },
                {
                  "self": "$jiraServer/rest/api/2/customFieldOption/10022",
                  "value": "Other",
                  "id": "10022"
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
      ]
    }
  ]
}
"@

    Describe "Get-JiraIssueCreateMetadata" {

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Get-JiraProject -ModuleName PSJira {
            [PSCustomObject] @{
                ID = $projectID;
                Name = $projectName;
            }
        }
        
        Mock Get-JiraIssueType -ModuleName PSJira {
            [PSCustomObject] @{
                ID = $issueTypeID;
                Name = $issueTypeName;
            }
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/issue/createmeta?projectIds=$projectID&issuetypeIds=$issueTypeID&expand=projects.issuetypes.fields"} {
            ConvertFrom-Json -InputObject $restResult
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName PSJira {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Queries Jira for metadata information about creating an issue" {
            $meta = Get-JiraIssueCreateMetadata -Project $projectID -IssueType $issueTypeName
            $meta | Should Not BeNullOrEmpty
            @($meta).Count | Should Be @((ConvertFrom-Json -InputObject $restResult).projects.issuetypes.fields | Get-Member -MemberType NoteProperty).Count
        }

        It "Returns fields in a format that is easy to filter and use" {
            @(Get-JiraIssueCreateMetadata -Project $projectID -IssueType $issueTypeName | ? {$_.Required -eq $true}).Count | Should Be 6
        }

        It "Sets the type name of the output objects to PSJira.CreateMetaField" {
            (Get-Member -InputObject (Get-JiraIssueCreateMetadata -Project $projectID -IssueType $issueTypeName)[0]).TypeName | Should Be 'PSJira.CreateMetaField'
        }

    }
}