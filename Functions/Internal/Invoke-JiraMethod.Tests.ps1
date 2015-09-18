$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "Invoke-JiraMethod" {

        $jiraServer = 'http://jiraserver.example.com'
        $issueKey = 'IT-3676'

        $testUsername = 'powershell-test'

        # Generated from a REST call to Atlassian's public Jira instance at the URI
        # listed below with a GUI tool. This way, we can just assume that the Web
        # request will work, whether or not Atlassian's servers are up.
        # This also allows us to test for specific expected values.
        $getResult = @"
{
  "expand": "renderedFields,names,schema,transitions,operations,editmeta,changelog",
  "id": "303853",
  "self": "https://jira.atlassian.com/rest/api/latest/issue/303853",
  "key": "DEMO-2719",
  "fields": {
    "issuetype": {
      "self": "https://jira.atlassian.com/rest/api/2/issuetype/2",
      "id": "2",
      "description": "A new feature of the product, which has yet to be developed.",
      "iconUrl": "https://jira.atlassian.com/images/icons/issuetypes/newfeature.png",
      "name": "New Feature",
      "subtask": false
    },
    "customfield_12130": null,
    "timespent": null,
    "customfield_10150": [
      "ben@atlassian.com(ben@atlassian.com)",
      "gokhant(gokhant)"
    ],
    "customfield_12131": null,
    "project": {
      "self": "https://jira.atlassian.com/rest/api/2/project/10820",
      "id": "10820",
      "key": "DEMO",
      "name": "Demo",
      "avatarUrls": {
        "48x48": "https://jira.atlassian.com/secure/projectavatar?pid=10820&avatarId=10011",
        "24x24": "https://jira.atlassian.com/secure/projectavatar?size=small&pid=10820&avatarId=10011",
        "16x16": "https://jira.atlassian.com/secure/projectavatar?size=xsmall&pid=10820&avatarId=10011",
        "32x32": "https://jira.atlassian.com/secure/projectavatar?size=medium&pid=10820&avatarId=10011"
      }
    },
    "customfield_14430": null,
    "customfield_10230": null,
    "fixVersions": [],
    "customfield_12730": null,
    "aggregatetimespent": null,
    "customfield_12531": "Not Started",
    "resolution": null,
    "customfield_11436": "216954",
    "customfield_11435": "216954",
    "customfield_11437": "216644",
    "resolutiondate": null,
    "workratio": -1,
    "lastViewed": "2014-12-17T14:19:32.364+0000",
    "watches": {
      "self": "https://jira.atlassian.com/rest/api/2/issue/DEMO-2719/watchers",
      "watchCount": 1,
      "isWatching": false
    },
    "customfield_10180": null,
    "created": "2013-10-26T20:06:23.853+0000",
    "customfield_11230": null,
    "priority": {
      "self": "https://jira.atlassian.com/rest/api/2/priority/4",
      "iconUrl": "https://jira.atlassian.com/images/icons/priorities/minor.png",
      "name": "Minor",
      "id": "4"
    },
    "customfield_11431": "233452",
    "customfield_11434": "216707",
    "customfield_11631": null,
    "labels": [],
    "customfield_11433": "224272",
    "customfield_12833": null,
    "customfield_12832": null,
    "customfield_14735": "0|11177c:",
    "aggregatetimeoriginalestimate": null,
    "timeestimate": null,
    "versions": [],
    "issuelinks": [
      {
        "id": "115932",
        "self": "https://jira.atlassian.com/rest/api/2/issueLink/115932",
        "type": {
          "id": "10080",
          "name": "Detail",
          "inward": "is detailed by",
          "outward": "details",
          "self": "https://jira.atlassian.com/rest/api/2/issueLinkType/10080"
        },
        "outwardIssue": {
          "id": "303848",
          "key": "DEMO-2717",
          "self": "https://jira.atlassian.com/rest/api/2/issue/303848",
          "fields": {
            "summary": "New Feature Test Task",
            "status": {
              "self": "https://jira.atlassian.com/rest/api/2/status/1",
              "description": "Issue is open and has not yet been accepted by Atlassian.",
              "iconUrl": "https://jira.atlassian.com/images/icons/statuses/open.png",
              "name": "Open",
              "id": "1",
              "statusCategory": {
                "self": "https://jira.atlassian.com/rest/api/2/statuscategory/2",
                "id": 2,
                "key": "new",
                "colorName": "blue-gray",
                "name": "To Do"
              }
            },
            "priority": {
              "self": "https://jira.atlassian.com/rest/api/2/priority/4",
              "iconUrl": "https://jira.atlassian.com/images/icons/priorities/minor.png",
              "name": "Minor",
              "id": "4"
            },
            "issuetype": {
              "self": "https://jira.atlassian.com/rest/api/2/issuetype/2",
              "id": "2",
              "description": "A new feature of the product, which has yet to be developed.",
              "iconUrl": "https://jira.atlassian.com/images/icons/issuetypes/newfeature.png",
              "name": "New Feature",
              "subtask": false
            }
          }
        }
      },
      {
        "id": "119483",
        "self": "https://jira.atlassian.com/rest/api/2/issueLink/119483",
        "type": {
          "id": "10000",
          "name": "Reference",
          "inward": "is related to",
          "outward": "relates to",
          "self": "https://jira.atlassian.com/rest/api/2/issueLinkType/10000"
        },
        "outwardIssue": {
          "id": "304302",
          "key": "DEMO-2722",
          "self": "https://jira.atlassian.com/rest/api/2/issue/304302",
          "fields": {
            "summary": "My summary",
            "status": {
              "self": "https://jira.atlassian.com/rest/api/2/status/1",
              "description": "Issue is open and has not yet been accepted by Atlassian.",
              "iconUrl": "https://jira.atlassian.com/images/icons/statuses/open.png",
              "name": "Open",
              "id": "1",
              "statusCategory": {
                "self": "https://jira.atlassian.com/rest/api/2/statuscategory/2",
                "id": 2,
                "key": "new",
                "colorName": "blue-gray",
                "name": "To Do"
              }
            },
            "priority": {
              "self": "https://jira.atlassian.com/rest/api/2/priority/4",
              "iconUrl": "https://jira.atlassian.com/images/icons/priorities/minor.png",
              "name": "Minor",
              "id": "4"
            },
            "issuetype": {
              "self": "https://jira.atlassian.com/rest/api/2/issuetype/1",
              "id": "1",
              "description": "A problem which impairs or prevents the functions of the product.",
              "iconUrl": "https://jira.atlassian.com/images/icons/issuetypes/bug.png",
              "name": "Bug",
              "subtask": false
            }
          }
        }
      },
      {
        "id": "115931",
        "self": "https://jira.atlassian.com/rest/api/2/issueLink/115931",
        "type": {
          "id": "10000",
          "name": "Reference",
          "inward": "is related to",
          "outward": "relates to",
          "self": "https://jira.atlassian.com/rest/api/2/issueLinkType/10000"
        },
        "inwardIssue": {
          "id": "303852",
          "key": "DEMO-2718",
          "self": "https://jira.atlassian.com/rest/api/2/issue/303852",
          "fields": {
            "summary": "REST ye merry gentlemen.",
            "status": {
              "self": "https://jira.atlassian.com/rest/api/2/status/1",
              "description": "Issue is open and has not yet been accepted by Atlassian.",
              "iconUrl": "https://jira.atlassian.com/images/icons/statuses/open.png",
              "name": "Open",
              "id": "1",
              "statusCategory": {
                "self": "https://jira.atlassian.com/rest/api/2/statuscategory/2",
                "id": 2,
                "key": "new",
                "colorName": "blue-gray",
                "name": "To Do"
              }
            },
            "priority": {
              "self": "https://jira.atlassian.com/rest/api/2/priority/4",
              "iconUrl": "https://jira.atlassian.com/images/icons/priorities/minor.png",
              "name": "Minor",
              "id": "4"
            },
            "issuetype": {
              "self": "https://jira.atlassian.com/rest/api/2/issuetype/2",
              "id": "2",
              "description": "A new feature of the product, which has yet to be developed.",
              "iconUrl": "https://jira.atlassian.com/images/icons/issuetypes/newfeature.png",
              "name": "New Feature",
              "subtask": false
            }
          }
        }
      }
    ],
    "assignee": {
      "self": "https://jira.atlassian.com/rest/api/2/user?username=ben%40atlassian.com",
      "name": "ben@atlassian.com",
      "key": "ben@atlassian.com",
      "emailAddress": "ben at atlassian dot com",
      "avatarUrls": {
        "48x48": "https://jira.atlassian.com/secure/useravatar?ownerId=ben%40atlassian.com&avatarId=72204",
        "24x24": "https://jira.atlassian.com/secure/useravatar?size=small&ownerId=ben%40atlassian.com&avatarId=72204",
        "16x16": "https://jira.atlassian.com/secure/useravatar?size=xsmall&ownerId=ben%40atlassian.com&avatarId=72204",
        "32x32": "https://jira.atlassian.com/secure/useravatar?size=medium&ownerId=ben%40atlassian.com&avatarId=72204"
      },
      "displayName": "Benjamin Naftzger [Atlassian]",
      "active": true,
      "timeZone": "Europe/Berlin"
    },
    "updated": "2013-12-08T11:00:43.133+0000",
    "status": {
      "self": "https://jira.atlassian.com/rest/api/2/status/1",
      "description": "Issue is open and has not yet been accepted by Atlassian.",
      "iconUrl": "https://jira.atlassian.com/images/icons/statuses/open.png",
      "name": "Open",
      "id": "1",
      "statusCategory": {
        "self": "https://jira.atlassian.com/rest/api/2/statuscategory/2",
        "id": 2,
        "key": "new",
        "colorName": "blue-gray",
        "name": "To Do"
      }
    },
    "components": [],
    "customfield_14330": null,
    "customfield_14130": null,
    "timeoriginalestimate": null,
    "description": "Creating of an issue using project keys and issue type names using the REST API",
    "customfield_14532": null,
    "customfield_12431": null,
    "customfield_12430": null,
    "customfield_10330": null,
    "customfield_12433": null,
    "customfield_10650": null,
    "customfield_14733": "0|113t9s:",
    "customfield_12432": null,
    "customfield_10651": null,
    "customfield_14734": "0|1115ag:",
    "customfield_12831": null,
    "customfield_12435": null,
    "customfield_14731": "1|hzqtcf:",
    "customfield_12830": null,
    "customfield_10653": null,
    "customfield_12434": null,
    "timetracking": {},
    "customfield_14732": "0|112g48:",
    "customfield_11930": null,
    "attachment": [],
    "aggregatetimeestimate": null,
    "summary": "REST ye merry gentlemen.",
    "creator": {
      "self": "https://jira.atlassian.com/rest/api/2/user?username=gokhant",
      "name": "gokhant",
      "key": "gokhant",
      "emailAddress": "gokhant at gmail dot com",
      "avatarUrls": {
        "48x48": "https://jira.atlassian.com/secure/useravatar?ownerId=gokhant&avatarId=73000",
        "24x24": "https://jira.atlassian.com/secure/useravatar?size=small&ownerId=gokhant&avatarId=73000",
        "16x16": "https://jira.atlassian.com/secure/useravatar?size=xsmall&ownerId=gokhant&avatarId=73000",
        "32x32": "https://jira.atlassian.com/secure/useravatar?size=medium&ownerId=gokhant&avatarId=73000"
      },
      "displayName": "Gokhan Tuna",
      "active": true,
      "timeZone": "Etc/UTC"
    },
    "subtasks": [],
    "customfield_13230": null,
    "customfield_10160": "35164800",
    "customfield_10161": "true",
    "customfield_11130": "232361",
    "customfield_13430": null,
    "customfield_13231": null,
    "customfield_10680": null,
    "reporter": {
      "self": "https://jira.atlassian.com/rest/api/2/user?username=gokhant",
      "name": "gokhant",
      "key": "gokhant",
      "emailAddress": "gokhant at gmail dot com",
      "avatarUrls": {
        "48x48": "https://jira.atlassian.com/secure/useravatar?ownerId=gokhant&avatarId=73000",
        "24x24": "https://jira.atlassian.com/secure/useravatar?size=small&ownerId=gokhant&avatarId=73000",
        "16x16": "https://jira.atlassian.com/secure/useravatar?size=xsmall&ownerId=gokhant&avatarId=73000",
        "32x32": "https://jira.atlassian.com/secure/useravatar?size=medium&ownerId=gokhant&avatarId=73000"
      },
      "displayName": "Gokhan Tuna",
      "active": true,
      "timeZone": "Etc/UTC"
    },
    "aggregateprogress": {
      "progress": 0,
      "total": 0
    },
    "customfield_11531": null,
    "customfield_12931": null,
    "environment": null,
    "duedate": null,
    "progress": {
      "progress": 0,
      "total": 0
    },
    "comment": {
      "startAt": 0,
      "maxResults": 1,
      "total": 1,
      "comments": [
        {
          "self": "https://jira.atlassian.com/rest/api/2/issue/303853/comment/534625",
          "id": "534625",
          "author": {
            "self": "https://jira.atlassian.com/rest/api/2/user?username=gokhant",
            "name": "gokhant",
            "key": "gokhant",
            "emailAddress": "gokhant at gmail dot com",
            "avatarUrls": {
              "48x48": "https://jira.atlassian.com/secure/useravatar?ownerId=gokhant&avatarId=73000",
              "24x24": "https://jira.atlassian.com/secure/useravatar?size=small&ownerId=gokhant&avatarId=73000",
              "16x16": "https://jira.atlassian.com/secure/useravatar?size=xsmall&ownerId=gokhant&avatarId=73000",
              "32x32": "https://jira.atlassian.com/secure/useravatar?size=medium&ownerId=gokhant&avatarId=73000"
            },
            "displayName": "Gokhan Tuna",
            "active": true,
            "timeZone": "Etc/UTC"
          },
          "body": "test comment",
          "updateAuthor": {
            "self": "https://jira.atlassian.com/rest/api/2/user?username=gokhant",
            "name": "gokhant",
            "key": "gokhant",
            "emailAddress": "gokhant at gmail dot com",
            "avatarUrls": {
              "48x48": "https://jira.atlassian.com/secure/useravatar?ownerId=gokhant&avatarId=73000",
              "24x24": "https://jira.atlassian.com/secure/useravatar?size=small&ownerId=gokhant&avatarId=73000",
              "16x16": "https://jira.atlassian.com/secure/useravatar?size=xsmall&ownerId=gokhant&avatarId=73000",
              "32x32": "https://jira.atlassian.com/secure/useravatar?size=medium&ownerId=gokhant&avatarId=73000"
            },
            "displayName": "Gokhan Tuna",
            "active": true,
            "timeZone": "Etc/UTC"
          },
          "created": "2013-11-05T02:50:09.991+0000",
          "updated": "2013-11-05T02:50:09.991+0000"
        }
      ]
    },
    "votes": {
      "self": "https://jira.atlassian.com/rest/api/2/issue/DEMO-2719/votes",
      "votes": 0,
      "hasVoted": false
    },
    "worklog": {
      "startAt": 0,
      "maxResults": 20,
      "total": 0,
      "worklogs": []
    }
  }
}
"@

        # Also generated from a REST call from an interactive PowerShell session
        $putResult = [PSCustomObject]@{
            'StatusCode'=204;
            'StatusDescription'='No Content';
            'Content' = @{};
            'RawContent' = @"
X-AREQUESTID: 584x212939x1
X-Seraph-LoginReason: OK
Set-Cookie: JSESSIONID=A1DD2528707AB1A228F84DE596F96124; Path=/jira; Secure; HttpOnly,atlassian.x
srf.token=AP7Z-4SHZ-ZT53-2O17|7676a73277120b8c0f31a7d439c389ccf9282456|lin; Path=/jira; Secure
Server: Apache-Coyote/1.1
X-ASESSIONID: 1nfxnyn
X-AUSERNAME: $testUsername
Cache-Control: no-cache, no-store, no-transform
X-Content-Type-Options: nosniff
Date: Wed, 17 Dec 2014 15:44:19 GMT
"@
            'Headers' = @{};
            'RawContentLength' = 0;
        }

        Mock Invoke-WebRequest -Verifiable -ParameterFilter {$Method -eq 'Get'} {
            Write-Output $getResult
        }

        Mock Invoke-WebRequest -Verifiable -ParameterFilter {$Method -eq 'Put'} {
            Write-Output $putResult
        }

        Mock Get-JiraSession -Verifiable {
            Write-Output @{
                'Username' = $testUsername;
            }
        }

        It "Performs a GET request to JIRA" {
            $getResult = Invoke-JiraMethod -Method Get -Uri 'https://jira.atlassian.com/rest/api/latest/issue/DEMO-2719'
            $getResult.id | Should Be 303853
            $getResult.self | Should Be 'https://jira.atlassian.com/rest/api/latest/issue/303853'
            $getResult | Should Not Be $null
            Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -Scope It
        }

        Mock ConvertFrom-Json -Verifiable {}

        It "Performs a PUT request to Jira" {
            $props = @{
                'update' = @{
                    'description' = @(
                        @{
                            'set' = 'Edited description!'
                        }
                    );
                };
            }
            $json = ConvertTo-Json -InputObject $props -Depth 3

            $putResult = Invoke-JiraMethod -Method Put -Uri "$jiraServer/rest/api/latest/issue/$issueKey" -Body $json
            Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -Scope It
            Assert-MockCalled -CommandName ConvertFrom-Json -Exactly 1 -Scope It
        }

        It "Uses Get-JiraSession to use a default Web session if credentials are not provided" {
            $getResult = Invoke-JiraMethod -Method Get -Uri 'https://jira.atlassian.com/rest/api/latest/issue/DEMO-2719'
            Assert-MockCalled -CommandName Get-JiraSession -Exactly -Times 1 -Scope It
        }
    }
}


