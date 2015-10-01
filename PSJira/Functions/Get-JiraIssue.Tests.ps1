param(
    [Parameter(Position = 0)]
    [bool] $ShowMockData
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $ShowMockData = $false

    $jiraServer = 'http://jiraserver.example.com'
    $issueID = 41701
    $issueKey = 'IT-3676'

    $issueID2 = 41702
    $issueKey2 = 'IT-3677'

    Describe "Get-JiraIssue" {
        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Context "Search for a single issue" {

            $restResult = @"
{
  "expand": "renderedFields,names,schema,transitions,operations,editmeta,changelog",
  "id": "$issueID",
  "self": "$jiraServer/rest/api/latest/issue/$issueID",
  "key": "$issueKey",
  "fields": {
    "issuetype": {
      "self": "$jiraServer/rest/api/2/issuetype/2",
      "id": "2",
      "description": "An issue related to end-user workstations.",
      "iconUrl": "$jiraServer/images/icons/issuetypes/newfeature.png",
      "name": "Desktop Support",
      "subtask": false
    },
    "description": "Test issue from PowerShell (created at an interactive shell).",
    "project": {
      "self": "$jiraServer/rest/api/2/project/10003",
      "id": "10003",
      "key": "IT",
      "name": "Information Technology"
    },
    "customfield_10012": ".",
    "summary": "Test issue",
    "created": "2015-05-01T10:39:12.000-0500",
    "priority": {
      "self": "$jiraServer/rest/api/2/priority/1",
      "iconUrl": "$jiraServer/images/icons/priorities/blocker.png",
      "name": "Critical",
      "id": "1"
    },
    "customfield_10002": ".",
    "comment": {
      "startAt": 0,
      "maxResults": 3,
      "total": 3,
      "comments": [
        {
          "self": "$jiraServer/rest/api/2/issue/$issueID/comment/90730",
          "id": "90730",
          "body": "Test comment"
        },
        {
          "self": "$jiraServer/rest/api/2/issue/$issueID/comment/90731",
          "id": "90731",
          "body": "Test comment"
        },
        {
          "self": "$jiraServer/rest/api/2/issue/$issueID/comment/90733",
          "id": "90733",
          "body": "Test comment from an interactive PowerShell session"
        }
      ]
    },
    "assignee": null,
    "updated": "2015-05-04T08:45:21.000-0500",
    "status": {
      "self": "$jiraServer/rest/api/2/status/3",
      "description": "This issue is being actively worked on at the moment by the assignee.",
      "iconUrl": "$jiraServer/images/icons/statuses/inprogress.png",
      "name": "In Progress",
      "id": "3",
      "statusCategory": {
        "self": "$jiraServer/rest/api/2/statuscategory/4",
        "id": 4,
        "key": "indeterminate",
        "colorName": "yellow",
        "name": "In Progress"
      }
    }
  },
  "transitions": [
    {
      "id": "81",
      "name": "Resolve",
      "to": {
        "self": "$jiraServer/rest/api/2/status/5",
        "description": "A resolution has been taken, and it is awaiting verification by reporter. From here issues are either reopened, or are closed.",
        "iconUrl": "$jiraServer/images/icons/statuses/resolved.png",
        "name": "Resolved",
        "id": "5",
        "statusCategory": {
          "self": "$jiraServer/rest/api/2/statuscategory/3",
          "id": 3,
          "key": "done",
          "colorName": "green",
          "name": "Complete"
        }
      }
    }
  ]
}
"@
            Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/issue/${issueKey}?expand=transitions"} {
                    if ($ShowMockData)
                    {
                        Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                        Write-Host "         [Method] $Method" -ForegroundColor Cyan
                        Write-Host "         [URI]    $URI" -ForegroundColor Cyan
                    }
                ConvertFrom-Json $restResult
            }

            Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/issue/${issueKey2}?expand=transitions"} {
                    if ($ShowMockData)
                    {
                        Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                        Write-Host "         [Method] $Method" -ForegroundColor Cyan
                        Write-Host "         [URI]    $URI" -ForegroundColor Cyan
                    }

                ConvertFrom-Json ($restResult -replace $issueKey, $issueKey2 -replace $issueID,$issueID2)
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName PSJira {
                Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
                Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
                Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
                throw "Unidentified call to Invoke-JiraMethod"
            }

#            Mock Write-Debug {
#                Write-Host "DEBUG: $Message" -ForegroundColor Yellow
#            }

            #############
            # Tests
            #############

            It "Gets information about a provided Jira issue" {
                $getResult = Get-JiraIssue -Key $issueKey
                $getResult | Should Not BeNullOrEmpty
                $getResult.Key | Should Be $issueKey
            }

            It "Converts the output object to PSJira.Issue" {
                $getResult = Get-JiraIssue -Key $issueKey
                (Get-Member -InputObject $getResult).TypeName | Should Be 'PSJira.Issue'
            }

            It "Returns multiple issues if passed to the Key parameter" {
                $results = Get-JiraIssue -Key $issueKey,$issueKey2
                $results | Should Not BeNullOrEmpty
                @($results).Count | Should Be 2
                $results[0].Key | Should Be $issueKey
                $results[1].Key | Should Be $issueKey2
            }

            It "Gets information for a provided Jira issue if a PSJira.Issue object is provided to the InputObject parameter" {
                $result1 = Get-JiraIssue -Key $issueKey
                $result2 = Get-JiraIssue -InputObject $result1
                $result2 | Should Not BeNullOrEmpty
                $result2.Key | Should Be $issueKey
            }

        }

        Context "Searching by query" {

            $restResult = @"
{
  "expand": "names,schema",
  "startAt": 0,
  "maxResults": 50,
  "total": 1,
  "issues": [
    {
      "expand": "renderedFields,names,schema,transitions,operations,editmeta,changelog",
      "id": "$issueID",
      "self": "$jiraServer/rest/api/latest/issue/$issueID",
      "key": "$issueKey",
      "fields": {
        "issuetype": {
          "self": "$jiraServer/rest/api/2/issuetype/2",
          "id": "2",
          "description": "An issue related to end-user workstations.",
          "iconUrl": "$jiraServer/images/icons/issuetypes/newfeature.png",
          "name": "Desktop Support",
          "subtask": false
        },
        "description": "Test issue from PowerShell (created at an interactive shell).",
        "project": {
          "self": "$jiraServer/rest/api/2/project/10003",
          "id": "10003",
          "key": "IT",
          "name": "Information Technology"
        },
        "customfield_10012": ".",
        "summary": "Test issue",
        "created": "2015-05-01T10:39:12.000-0500",
        "priority": {
          "self": "$jiraServer/rest/api/2/priority/1",
          "iconUrl": "$jiraServer/images/icons/priorities/blocker.png",
          "name": "Critical",
          "id": "1"
        },
        "customfield_10002": ".",
        "comment": {
          "startAt": 0,
          "maxResults": 3,
          "total": 3,
          "comments": [
            {
              "self": "$jiraServer/rest/api/2/issue/$issueID/comment/90730",
              "id": "90730",
              "body": "Test comment"
            },
            {
              "self": "$jiraServer/rest/api/2/issue/$issueID/comment/90731",
              "id": "90731",
              "body": "Test comment"
            },
            {
              "self": "$jiraServer/rest/api/2/issue/$issueID/comment/90733",
              "id": "90733",
              "body": "Test comment from an interactive PowerShell session"
            }
          ]
        },
        "assignee": null,
        "updated": "2015-05-04T08:45:21.000-0500",
        "status": {
          "self": "$jiraServer/rest/api/2/status/3",
          "description": "This issue is being actively worked on at the moment by the assignee.",
          "iconUrl": "$jiraServer/images/icons/statuses/inprogress.png",
          "name": "In Progress",
          "id": "3",
          "statusCategory": {
            "self": "$jiraServer/rest/api/2/statuscategory/4",
            "id": 4,
            "key": "indeterminate",
            "colorName": "yellow",
            "name": "In Progress"
          }
        }
      },
      "transitions": [
        {
          "id": "81",
          "name": "Resolve",
          "to": {
            "self": "$jiraServer/rest/api/2/status/5",
            "description": "A resolution has been taken, and it is awaiting verification by reporter. From here issues are either reopened, or are closed.",
            "iconUrl": "$jiraServer/images/icons/statuses/resolved.png",
            "name": "Resolved",
            "id": "5",
            "statusCategory": {
              "self": "$jiraServer/rest/api/2/statuscategory/3",
              "id": 3,
              "key": "done",
              "colorName": "green",
              "name": "Complete"
            }
          }
        }
      ]
    }
  ]
}
"@

            Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/search?jql=text~""test""*"} {
                    if ($ShowMockData)
                    {
                        Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                        Write-Host "         [Method] $Method" -ForegroundColor Cyan
                        Write-Host "         [URI]    $URI" -ForegroundColor Cyan
                    }
                ConvertFrom-Json -InputObject $restResult
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName PSJira {
                Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
                Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
                Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
                throw "Unidentified call to Invoke-JiraMethod"
            }

            It "Searches Jira using the provided query if a JQL query is provided to the -Query parameter" {
                $result = Get-JiraIssue -Query 'text~"test"'
                $result | Should Not BeNullOrEmpty
                $result.Key | Should Be $issueKey
            }
        }
    }
}


