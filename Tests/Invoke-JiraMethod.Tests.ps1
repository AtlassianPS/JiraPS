Describe "Invoke-JiraMethod" {

    Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

        $validMethods = @('GET', 'POST', 'PUT', 'DELETE')

        Context "Sanity checking" {
            $command = Get-Command -Name Invoke-JiraMethod

            defParam $command 'URI'
            defParam $command 'Method'
            defParam $command 'Body'
            defParam $command 'RawBody'
            defParam $command 'Headers'
            defParam $command 'InFile'
            defParam $command 'OutFile'
            defParam $command 'Credential'
            defParam $command 'CmdLet'

            It "Restricts the METHODs to WebRequestMethod" {
                $methodType = $command.Parameters.Method.ParameterType
                $methodType.FullName | Should Be "Microsoft.PowerShell.Commands.WebRequestMethod"
            }
        }

        Context "Behavior testing" {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]

            $testUri = 'http://example.com'
            $testUsername = 'testUsername'
            $testPassword = 'password123'
            $testCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $testUsername, (ConvertTo-SecureString -AsPlainText -Force $testPassword)

            Mock Invoke-WebRequest {
                ShowMockInfo 'Invoke-WebRequest' -Params 'Uri', 'Method'
            }

            It "Correctly performs all necessary HTTP method requests [$($validMethods -join ',')] to a provided URI" {
                foreach ($method in $validMethods) {
                    { Invoke-JiraMethod -Method $method -URI $testUri } | Should Not Throw

                    Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$Method -eq $method -and $Uri -eq $testUri} -Scope It
                }
            }

            It "Uses the -ContentType parameter of Invoke-WebRequest to specify application/json and UTF-8" {
                { Invoke-JiraMethod -Method Get -URI $testUri } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$ContentType -eq 'application/json; charset=utf-8'} -Scope It
            }

            It "Uses the -UseBasicParsing switch for Invoke-WebRequest" {
                { Invoke-JiraMethod -Method Get -URI $testUri } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$UseBasicParsing -eq $true} -Scope It
            }

        }

        $validTestUri = 'https://jira.atlassian.com/rest/api/latest/issue/303853'

        # This is a real REST result from Atlassian's public-facing JIRA instance, trimmed and cleaned
        # up just a bit for fields we don't care about.

        # You can obtain this data with a single PowerShell line:
        # Invoke-WebRequest -Method Get -Uri https://jira.atlassian.com/rest/api/latest/issue/303853
        $validRestResult = @'
{
    "expand": "renderedFields,names,schema,transitions,operations,editmeta,changelog,versionedRepresentations",
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
        "timespent": null,
        "project": {
            "self": "https://jira.atlassian.com/rest/api/2/project/10820",
            "id": "10820",
            "key": "DEMO",
            "name": "Demo",
            "avatarUrls": {
                "48x48": "https://jira.atlassian.com/secure/projectavatar?avatarId=10011",
                "24x24": "https://jira.atlassian.com/secure/projectavatar?size=small&avatarId=10011",
                "16x16": "https://jira.atlassian.com/secure/projectavatar?size=xsmall&avatarId=10011",
                "32x32": "https://jira.atlassian.com/secure/projectavatar?size=medium&avatarId=10011"
            }
        },
        "fixVersions": [],
        "aggregatetimespent": null,
        "resolution": null,
        "resolutiondate": null,
        "workratio": -1,
        "lastViewed": null,
        "watches": {
            "self": "https://jira.atlassian.com/rest/api/2/issue/DEMO-2719/watchers",
            "watchCount": 1,
            "isWatching": false
        },
        "created": "2013-10-26T20:06:23.853+0000",
        "priority": {
            "self": "https://jira.atlassian.com/rest/api/2/priority/4",
            "iconUrl": "https://jira.atlassian.com/images/icons/priorities/minor.png",
            "name": "Minor",
            "id": "4"
        },
        "labels": [],
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
        "timeoriginalestimate": null,
        "description": "Creating of an issue using project keys and issue type names using the REST API",
        "timetracking": {},
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
'@

        $validObjResult = ConvertFrom-Json -InputObject $validRestResult

        Context "Output handling - valid object returned (HTTP 200)" {

            It "Outputs an object representation of JSON returned from JIRA" {

                Mock Invoke-WebRequest -ParameterFilter {$Method -eq 'Get' -and $Uri -eq $validTestUri} {
                    ShowMockInfo 'Invoke-WebRequest' -Params 'Uri', 'Method'
                    Write-Output [PSCustomObject] @{
                        'Content' = $validRestResult
                    }
                }

                $result = Invoke-JiraMethod -Method Get -URI $validTestUri
                $result | Should Not BeNullOrEmpty

                # Compare each property in the result returned to the expected result
                foreach ($property in (Get-Member -InputObject $result | Where-Object {$_.MemberType -eq 'NoteProperty'})) {
                    $result.$property | Should Be $validObjResult.$property
                }
            }
        }

        Context "Output handling - no content returned (HTTP 204)" {
            Mock Invoke-WebRequest {
                ShowMockInfo 'Invoke-WebRequest' -Params 'Uri', 'Method'

                Write-Output [PSCustomObject] @{
                    'StatusCode' = 204
                    'Content'    = $null
                }
            }
            Mock ConvertFrom-Json {
                ShowMockInfo 'ConvertFrom-Json'
            }

            It "Correctly handles HTTP response codes that do not provide a return body" {
                { Invoke-JiraMethod -Method Get -URI $validTestUri } | Should Not Throw
                Assert-MockCalled -CommandName ConvertFrom-Json -Exactly -Times 0 -Scope It
            }
        }

        Context "Output handling - JIRA error returned (HTTP 400 and up)" {
            $invalidTestUri = 'https://jira.atlassian.com/rest/api/latest/issue/1'
            $invalidRestResult = '{"errorMessages":["Issue Does Not Exist"],"errors":{}}'

            Mock Invoke-WebRequest {
                ShowMockInfo 'Invoke-WebRequest' -Params 'Uri', 'Method'
                Write-Output [PSCustomObject] @{
                    'StatusCode' = 400
                    'Content'    = $invalidRestResult
                }
            }

            Mock Resolve-JiraError {
                ShowMockInfo 'Resolve-JiraError' -params 'InputObject'
            }

            It "Uses Resolve-JiraError to parse any JIRA error messages returned" {
                { Invoke-JiraMethod -Method Get -URI $invalidTestUri } | Should Not Throw
                Assert-MockCalled -CommandName Resolve-JiraError -Exactly -Times 1 -Scope It
            }
        }
    }
}
