#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "ConvertTo-JiraIssue" -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        if ($projectRoot -like "*Release") {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }

        Import-Module BuildHelpers
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

        $env:BHManifestToTest = $env:BHPSModuleManifest
        $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($script:isBuild) {
            $Pattern = [regex]::Escape($env:BHProjectPath)

            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'

        # An example of how an issue will look when returned from JIRA's REST API.
        # You can obtain most of this with a one-liner:
        # (Invoke-WebRequest -Method Get -Uri '$jiraServer/rest/api/latest/issue/JRA-37294?expand=transitions').Content

        # I have edited the result just a bit to add a fake Transitions
        # property that matches the expected results from JIRA. I'm not
        # authorized to view issue transitions on Atlassian's JIRA instance,
        # so I created one in order to better test the function.
        $sampleJson = @"
{
    "expand": "renderedFields,names,schema,transitions,operations,editmeta,changelog,versionedRepresentations",
    "id": "320391",
    "self": "$jiraServer/rest/api/latest/issue/320391",
    "key": "JRA-37294",
    "fields": {
        "customfield_12130": null,
        "customfield_12131": null,
        "customfield_14430": null,
        "customfield_10230": null,
        "fixVersions": [],
        "resolution": null,
        "customfield_12531": "Not Started",
        "customfield_14830": "<div class=\"aui-message\">\r\n    <p>Thanks for taking the time to raise a Suggestion for JIRA, Atlassian values your input.\r\n\t\t\t<br/>\r\n\t\t\t<br/>\r\n\t\t\tWe receive feedback from a number of different sources and evaluate those when we plan our product roadmap. If you would like to know more about how the JIRA Product Management team uses your input in our planning process, please see <a href = \"https://answers.atlassian.com/questions/110373/how-does-the-jira-team-use-jira-atlassian-com\">our post on Atlassian Answers</a>.\r\n\t\t\t<br/>\r\n\t\t\t<br/>\r\n\t\t\tBefore creating a new Suggestion, please search the existing issues to see if your suggestion already exists. Otherwise, please fill in the fields below with the use case for your suggestion.\r\n\t\t\t<br/>\r\n\t\t\t<br/>\r\n\t\t\tKind Regards,\r\n\t\t\t<br/>\r\n\t\t\tJIRA Product Management Team</p>\r\n<span class=\"aui-icon icon-info\"></span>\r\n</div>",
        "customfield_12930": null,
        "customfield_11436": "232674",
        "customfield_11435": "232674",
        "customfield_11437": "232344",
        "lastViewed": null,
        "customfield_10180": null,
        "customfield_11431": "246625",
        "customfield_11434": "232412",
        "labels": [],
        "customfield_11433": "241201",
        "customfield_10610": null,
        "aggregatetimeoriginalestimate": null,
        "timeestimate": null,
        "versions": [],
        "issuelinks": [],
        "assignee": null,
        "status": {
            "self": "$jiraServer/images/icons/statuses/open.png",
            "name": "Open",
            "id": "1",
            "statusCategory": {
                "self": "$jiraServer/rest/api/2/statuscategory/2",
                "id": 2,
                "key": "new",
                "colorName": "blue-gray",
                "name": "To Do"
            }
        },
        "customfield_16030": null,
        "components": [
            {
                "self": "$jiraServer/rest/api/2/component/13170",
                "id": "13170",
                "name": "Remote API (REST)",
                "description": "Issues affecting JIRA's REST API"
            }
        ],
        "customfield_14130": null,
        "customfield_14532": null,
        "customfield_10571": null,
        "customfield_12630": null,
        "customfield_10575": null,
        "customfield_14930": "<div class=\"aui-message\">\r\n    <p>JIRA feedback is collected from a number of different sources and is evaluated when planning the product roadmap. If you would like to know more about how JIRA Product Management uses customer input during the planning process, please see <a href = \"https://answers.atlassian.com/questions/110373/how-does-the-jira-team-use-jira-atlassian-com\">our post on Atlassian Answers</a>.\r\n</p>\r\n<span class=\"aui-icon icon-info\"></span>\r\n</div>",
        "customfield_11930": null,
        "customfield_10723": null,
        "aggregatetimeestimate": null,
        "creator": {
            "self": "$jiraServer/rest/api/2/user?username=takindele",
            "name": "takindele",
            "key": "takindele",
            "emailAddress": "takindele at atlassian dot com",
            "avatarUrls": {
                "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
            },
            "displayName": "Taiwo Akindele [Atlassian]",
            "active": true,
            "timeZone": "Asia/Shanghai"
        },
        "customfield_15331": null,
        "subtasks": [],
        "customfield_10160": "604800",
        "customfield_10161": "true",
        "customfield_13430": null,
        "customfield_11130": "247167",
        "customfield_10680": null,
        "reporter": {
            "self": "$jiraServer/rest/api/2/user?username=takindele",
            "name": "takindele",
            "key": "takindele",
            "emailAddress": "takindele at atlassian dot com",
            "avatarUrls": {
                "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
            },
            "displayName": "Taiwo Akindele [Atlassian]",
            "active": true,
            "timeZone": "Asia/Shanghai"
        },
        "aggregateprogress": {
            "progress": 0,
            "total": 0
        },
        "customfield_11531": null,
        "progress": {
            "progress": 0,
            "total": 0
        },
        "votes": {
            "self": "$jiraServer/rest/api/2/issue/JRA-37294/votes",
            "votes": 50,
            "hasVoted": false
        },
        "worklog": {
            "startAt": 0,
            "maxResults": 20,
            "total": 0,
            "worklogs": []
        },
        "issuetype": {
            "self": "$jiraServer/rest/api/2/issuetype/10000",
            "id": "10000",
            "description": "",
            "iconUrl": "$jiraServer/secure/viewavatar?size=xsmall&avatarId=51505&avatarType=issuetype",
            "name": "Suggestion",
            "subtask": false,
            "avatarId": 51505
        },
        "timespent": null,
        "customfield_10150": [
            "intersol_OLD(intersol_old)",
            "congnv(congnv)",
            "jhu(jhu)",
            "markdw(markdw)",
            "matt.doar(matt.doar)",
            "fanno(fanno)",
            "sean26(sean26)",
            "stanislaw(stanislaw)",
            "takindele(takindele)",
            "torben.hoeft(torben.hoeft)"
        ],
        "project": {
            "self": "$jiraServer/rest/api/2/project/10240",
            "id": "10240",
            "key": "JRA",
            "name": "JIRA (including JIRA Core)",
            "avatarUrls": {
                "48x48": "$jiraServer/secure/projectavatar?pid=10240&avatarId=17294",
                "24x24": "$jiraServer/secure/projectavatar?size=small&pid=10240&avatarId=17294",
                "16x16": "$jiraServer/secure/projectavatar?size=xsmall&pid=10240&avatarId=17294",
                "32x32": "$jiraServer/secure/projectavatar?size=medium&pid=10240&avatarId=17294"
            },
            "projectCategory": {
                "self": "$jiraServer/rest/api/2/projectCategory/10031",
                "id": "10031",
                "description": "",
                "name": "Atlassian Products"
            }
        },
        "customfield_12730": null,
        "aggregatetimespent": null,
        "resolutiondate": null,
        "workratio": -1,
        "watches": {
            "self": "$jiraServer/rest/api/2/issue/JRA-37294/watchers",
            "watchCount": 32,
            "isWatching": false
        },
        "customfield_15430": null,
        "created": "2014-03-03T08:11:56.394+0000",
        "customfield_11230": null,
        "customfield_15830": null,
        "customfield_11631": null,
        "customfield_12833": null,
        "customfield_12832": null,
        "customfield_14735": "0|113w60:",
        "updated": "2015-11-27T06:48:08.068+0000",
        "customfield_14330": null,
        "timeoriginalestimate": null,
        "description": "Currently it appears the /rest/api/2/user (PUT) API doesn't provide facility to set users active or inactive, or perhaps the request representation doesn't include how this is done. Currently the API works fine for the following fields:\r\n{code}\r\n{\r\n    \"name\": \"eddie\",\r\n    \"emailAddress\": \"eddie@atlassian.com\",\r\n    \"displayName\": \"Eddie of Atlassian\"\r\n}\r\n{code}\r\n\r\nCan something like {{\"Active\": 1}} or {{\"Active\": true}} be made available for this API as well to set the Activate or de-activate a user?",
        "customfield_12431": null,
        "customfield_12430": null,
        "customfield_14733": "1|hzfr13:",
        "customfield_10650": null,
        "customfield_12433": null,
        "customfield_10651": null,
        "customfield_14734": "0|113u4g:",
        "customfield_12432": null,
        "customfield_12435": null,
        "customfield_14731": "2|hzrfun:",
        "customfield_12831": null,
        "timetracking": {},
        "customfield_14732": "0|115cjc:",
        "customfield_12830": null,
        "customfield_12434": null,
        "customfield_10653": null,
        "customfield_10401": null,
        "attachment": [
            {
                "self": "$jiraServer/rest/api/2/attachment/270709",
                "id": "270709",
                "filename": "Nav2-HCF.PNG",
                "author": {
                    "self": "$jiraServer/rest/api/2/user?username=JonDoe",
                    "name": "JonDoe",
                    "key": "JonDoe",
                    "emailAddress": "user@server.com",
                    "avatarUrls": {}
                },
                "created": "2017-05-30T11:20:34.000+0000",
                "size": 366272,
                "mimeType": "image/png",
                "content": "$jiraServer/secure/attachment/270709/Nav2-HCF.PNG",
                "thumbnail": "$jiraServer/secure/thumbnail/270709/_thumb_270709.png"
            },
            {
                "self": "$jiraServer/rest/api/2/attachment/270656",
                "id": "270656",
                "filename": "Nav-HCF.PNG",
                "author": {},
                "created": "2017-05-30T09:26:17.000+0000",
                "size": 548806,
                "mimeType": "image/png",
                "content": "$jiraServer/secure/attachment/270656/Nav-HCF.PNG",
                "thumbnail": "$jiraServer/secure/thumbnail/270656/_thumb_270656.png"
            }
        ],
        "summary": "Allow set active/inactive via REST API",
        "customfield_13230": "2014-03-03 20:48:03.646",
        "customfield_15532": null,
        "customfield_13231": null,
        "customfield_15530": null,
        "customfield_15932": null,
        "customfield_15930": null,
        "customfield_15931": null,
        "customfield_12931": null,
        "environment": null,
        "duedate": null,
        "comment": {
            "startAt": 0,
            "maxResults": 16,
            "total": 16,
            "comments": [
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/573751",
                    "id": "573751",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=fanno",
                        "name": "fanno",
                        "key": "fanno",
                        "emailAddress": "fannoj at gmail dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=fanno&avatarId=78570",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=fanno&avatarId=78570",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=fanno&avatarId=78570",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=fanno&avatarId=78570"
                        },
                        "displayName": "Morten Hundevad",
                        "active": true,
                        "timeZone": "Europe/Berlin"
                    },
                    "body": "i just tested with \r\n\r\ntrue/false aswell it gives same result\r\n\r\nthis to be excact\r\n{code}\r\nerror.no.value.found.to.be.changed\r\n{code}\r\n\r\n-Thanks",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=fanno",
                        "name": "fanno",
                        "key": "fanno",
                        "emailAddress": "fannoj at gmail dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=fanno&avatarId=78570",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=fanno&avatarId=78570",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=fanno&avatarId=78570",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=fanno&avatarId=78570"
                        },
                        "displayName": "Morten Hundevad",
                        "active": true,
                        "timeZone": "Europe/Berlin"
                    },
                    "created": "2014-03-03T20:48:03.646+0000",
                    "updated": "2014-03-03T20:48:03.646+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/589184",
                    "id": "589184",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=intersol_OLD",
                        "name": "intersol_OLD",
                        "key": "intersol_old",
                        "emailAddress": "sorin dot sbarnea at citrix dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Citrix Devops",
                        "active": false,
                        "timeZone": "Europe/London"
                    },
                    "body": "The same problems applies for username, which is supposed to be updated this way (6.2+)",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=intersol_OLD",
                        "name": "intersol_OLD",
                        "key": "intersol_old",
                        "emailAddress": "sorin dot sbarnea at citrix dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Citrix Devops",
                        "active": false,
                        "timeZone": "Europe/London"
                    },
                    "created": "2014-04-12T13:38:24.356+0000",
                    "updated": "2014-04-12T13:38:24.356+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/623287",
                    "id": "623287",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=matt.doar",
                        "name": "matt.doar",
                        "key": "matt.doar",
                        "emailAddress": "matt dot doar at servicerocket dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=matt.doar&avatarId=66289",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=matt.doar&avatarId=66289",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=matt.doar&avatarId=66289",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=matt.doar&avatarId=66289"
                        },
                        "displayName": "Matt Doar [ServiceRocket]",
                        "active": true,
                        "timeZone": "America/Los_Angeles"
                    },
                    "body": "This is really painful to workaround. ",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=matt.doar",
                        "name": "matt.doar",
                        "key": "matt.doar",
                        "emailAddress": "matt dot doar at servicerocket dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=matt.doar&avatarId=66289",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=matt.doar&avatarId=66289",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=matt.doar&avatarId=66289",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=matt.doar&avatarId=66289"
                        },
                        "displayName": "Matt Doar [ServiceRocket]",
                        "active": true,
                        "timeZone": "America/Los_Angeles"
                    },
                    "created": "2014-07-21T18:01:01.560+0000",
                    "updated": "2014-07-21T18:01:01.560+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/623380",
                    "id": "623380",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=fanno",
                        "name": "fanno",
                        "key": "fanno",
                        "emailAddress": "fannoj at gmail dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=fanno&avatarId=78570",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=fanno&avatarId=78570",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=fanno&avatarId=78570",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=fanno&avatarId=78570"
                        },
                        "displayName": "Morten Hundevad",
                        "active": true,
                        "timeZone": "Europe/Berlin"
                    },
                    "body": "@Matt Doar\r\n\r\nIs there a workaround at all?\r\n\r\n-Thanks",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=fanno",
                        "name": "fanno",
                        "key": "fanno",
                        "emailAddress": "fannoj at gmail dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=fanno&avatarId=78570",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=fanno&avatarId=78570",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=fanno&avatarId=78570",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=fanno&avatarId=78570"
                        },
                        "displayName": "Morten Hundevad",
                        "active": true,
                        "timeZone": "Europe/Berlin"
                    },
                    "created": "2014-07-21T20:22:37.867+0000",
                    "updated": "2014-07-21T20:22:37.867+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/623669",
                    "id": "623669",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=matt.doar",
                        "name": "matt.doar",
                        "key": "matt.doar",
                        "emailAddress": "matt dot doar at servicerocket dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=matt.doar&avatarId=66289",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=matt.doar&avatarId=66289",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=matt.doar&avatarId=66289",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=matt.doar&avatarId=66289"
                        },
                        "displayName": "Matt Doar [ServiceRocket]",
                        "active": true,
                        "timeZone": "America/Los_Angeles"
                    },
                    "body": "Not that I know of",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=matt.doar",
                        "name": "matt.doar",
                        "key": "matt.doar",
                        "emailAddress": "matt dot doar at servicerocket dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=matt.doar&avatarId=66289",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=matt.doar&avatarId=66289",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=matt.doar&avatarId=66289",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=matt.doar&avatarId=66289"
                        },
                        "displayName": "Matt Doar [ServiceRocket]",
                        "active": true,
                        "timeZone": "America/Los_Angeles"
                    },
                    "created": "2014-07-22T15:47:34.834+0000",
                    "updated": "2014-07-22T15:47:34.834+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/634580",
                    "id": "634580",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=jhu",
                        "name": "jhu",
                        "key": "jhu",
                        "emailAddress": "jhu at woodwing dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Joost Huizinga",
                        "active": true,
                        "timeZone": "Europe/Berlin"
                    },
                    "body": "The absence of this field in the API makes migration from an old system to Jira a pain. Users that existed in the old system but no longer work for the company and therefore are not present in Jira need to be created in Jira for the migration purpose. This can be automated but since the field is missing, all added users need be set to inactive by hand afterwards.",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=jhu",
                        "name": "jhu",
                        "key": "jhu",
                        "emailAddress": "jhu at woodwing dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Joost Huizinga",
                        "active": true,
                        "timeZone": "Europe/Berlin"
                    },
                    "created": "2014-08-22T08:53:46.719+0000",
                    "updated": "2014-08-22T08:53:46.719+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/684791",
                    "id": "684791",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=matt.doar",
                        "name": "matt.doar",
                        "key": "matt.doar",
                        "emailAddress": "matt dot doar at servicerocket dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=matt.doar&avatarId=66289",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=matt.doar&avatarId=66289",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=matt.doar&avatarId=66289",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=matt.doar&avatarId=66289"
                        },
                        "displayName": "Matt Doar [ServiceRocket]",
                        "active": true,
                        "timeZone": "America/Los_Angeles"
                    },
                    "body": "I use script runner scripts to do this nowadays",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=matt.doar",
                        "name": "matt.doar",
                        "key": "matt.doar",
                        "emailAddress": "matt dot doar at servicerocket dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=matt.doar&avatarId=66289",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=matt.doar&avatarId=66289",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=matt.doar&avatarId=66289",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=matt.doar&avatarId=66289"
                        },
                        "displayName": "Matt Doar [ServiceRocket]",
                        "active": true,
                        "timeZone": "America/Los_Angeles"
                    },
                    "created": "2014-12-29T21:22:23.057+0000",
                    "updated": "2014-12-29T21:22:23.057+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/706972",
                    "id": "706972",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=markdw",
                        "name": "markdw",
                        "key": "markdw",
                        "emailAddress": "mdwilliams1 at dstsystems dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=markdw&avatarId=66693",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=markdw&avatarId=66693",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=markdw&avatarId=66693",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=markdw&avatarId=66693"
                        },
                        "displayName": "MarkW",
                        "active": true,
                        "timeZone": "America/Chicago"
                    },
                    "body": "This is much needed. We need to mark users that no longer work with the company as inactive in an automated fashion. It is a shame that it is not included in the API.",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=markdw",
                        "name": "markdw",
                        "key": "markdw",
                        "emailAddress": "mdwilliams1 at dstsystems dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=markdw&avatarId=66693",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=markdw&avatarId=66693",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=markdw&avatarId=66693",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=markdw&avatarId=66693"
                        },
                        "displayName": "MarkW",
                        "active": true,
                        "timeZone": "America/Chicago"
                    },
                    "created": "2015-03-04T17:33:43.155+0000",
                    "updated": "2015-03-04T17:33:43.155+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/712103",
                    "id": "712103",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=sean26",
                        "name": "sean26",
                        "key": "sean26",
                        "emailAddress": "sean at squareup dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=sean26&avatarId=74797",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=sean26&avatarId=74797",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=sean26&avatarId=74797",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=sean26&avatarId=74797"
                        },
                        "displayName": "Sean Lazar",
                        "active": true,
                        "timeZone": "America/Los_Angeles"
                    },
                    "body": "I definitely could use this.",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=sean26",
                        "name": "sean26",
                        "key": "sean26",
                        "emailAddress": "sean at squareup dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=sean26&avatarId=74797",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=sean26&avatarId=74797",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=sean26&avatarId=74797",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=sean26&avatarId=74797"
                        },
                        "displayName": "Sean Lazar",
                        "active": true,
                        "timeZone": "America/Los_Angeles"
                    },
                    "created": "2015-03-19T00:01:36.701+0000",
                    "updated": "2015-03-19T00:01:36.701+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/732650",
                    "id": "732650",
                    "author": {
                        "self": "$jiraServer/secure/useravatar?avatarId=10612",
                        "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                        "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                        "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                    },
                    "displayName": "Torben Hoeft",
                    "active": true,
                    "timeZone": "Etc/UTC",
                    "body": "in the REST documentation is written \"Modify user. The \"value\" fields present will override the existing value. Fields skipped in request will not be changed.\"\r\nIf I do a GET on the user, I can see that the user is \"active\": true or \"active\": false. So I expect that I can update this values with a put.\r\nPlease make this available or do a better documentation. I prefer the first option ;-)",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=torben.hoeft",
                        "name": "torben.hoeft",
                        "key": "torben.hoeft",
                        "emailAddress": "torben dot hoeft at swisscom dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Torben Hoeft",
                        "active": true,
                        "timeZone": "Etc/UTC"
                    },
                    "created": "2015-05-07T13:15:57.596+0000",
                    "updated": "2015-05-07T13:15:57.596+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/746403",
                    "id": "746403",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=congnv",
                        "name": "congnv",
                        "key": "congnv",
                        "emailAddress": "congnv at smartosc dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Cong Nguyen Van",
                        "active": true,
                        "timeZone": "Etc/UTC"
                    },
                    "body": "Could update any method or provide full api for us?",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=congnv",
                        "name": "congnv",
                        "key": "congnv",
                        "emailAddress": "congnv at smartosc dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Cong Nguyen Van",
                        "active": true,
                        "timeZone": "Etc/UTC"
                    },
                    "created": "2015-06-05T04:03:44.872+0000",
                    "updated": "2015-06-05T04:03:44.872+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/746450",
                    "id": "746450",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=torben.hoeft",
                        "name": "torben.hoeft",
                        "key": "torben.hoeft",
                        "emailAddress": "torben dot hoeft at swisscom dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Torben Hoeft",
                        "active": true,
                        "timeZone": "Etc/UTC"
                    },
                    "body": "as a transitional solution we have written a small Plugin which offers a REST API to change the value.",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=torben.hoeft",
                        "name": "torben.hoeft",
                        "key": "torben.hoeft",
                        "emailAddress": "torben dot hoeft at swisscom dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Torben Hoeft",
                        "active": true,
                        "timeZone": "Etc/UTC"
                    },
                    "created": "2015-06-05T07:14:45.253+0000",
                    "updated": "2015-06-05T07:14:45.253+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/823128",
                    "id": "823128",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=stanislaw",
                        "name": "stanislaw",
                        "key": "stanislaw",
                        "emailAddress": "stanislaw dot kodzis at sabre dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Stanislaw Kodzis",
                        "active": true,
                        "timeZone": "Etc/UTC"
                    },
                    "body": "+1 Very needed feature!",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=stanislaw",
                        "name": "stanislaw",
                        "key": "stanislaw",
                        "emailAddress": "stanislaw dot kodzis at sabre dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Stanislaw Kodzis",
                        "active": true,
                        "timeZone": "Etc/UTC"
                    },
                    "created": "2015-11-09T11:48:39.412+0000",
                    "updated": "2015-11-09T11:48:39.412+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/823304",
                    "id": "823304",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=fanno",
                        "name": "fanno",
                        "key": "fanno",
                        "emailAddress": "fannoj at gmail dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=fanno&avatarId=78570",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=fanno&avatarId=78570",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=fanno&avatarId=78570",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=fanno&avatarId=78570"
                        },
                        "displayName": "Morten Hundevad",
                        "active": true,
                        "timeZone": "Europe/Berlin"
                    },
                    "body": "Is anyone even looking at this? How many vote are needed? ",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=fanno",
                        "name": "fanno",
                        "key": "fanno",
                        "emailAddress": "fannoj at gmail dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=fanno&avatarId=78570",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=fanno&avatarId=78570",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=fanno&avatarId=78570",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=fanno&avatarId=78570"
                        },
                        "displayName": "Morten Hundevad",
                        "active": true,
                        "timeZone": "Europe/Berlin"
                    },
                    "created": "2015-11-09T18:26:17.295+0000",
                    "updated": "2015-11-09T18:26:17.295+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/823427",
                    "id": "823427",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=torben.hoeft",
                        "name": "torben.hoeft",
                        "key": "torben.hoeft",
                        "emailAddress": "torben dot hoeft at swisscom dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Torben Hoeft",
                        "active": true,
                        "timeZone": "Etc/UTC"
                    },
                    "body": "We have extended the REST API with this functionality. I'll check if we can put this for free on the marketplace or at least make it public on bitbucket.\r\n\r\nIf interested please leave a comment",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=torben.hoeft",
                        "name": "torben.hoeft",
                        "key": "torben.hoeft",
                        "emailAddress": "torben dot hoeft at swisscom dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?avatarId=10612",
                            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612"
                        },
                        "displayName": "Torben Hoeft",
                        "active": true,
                        "timeZone": "Etc/UTC"
                    },
                    "created": "2015-11-09T19:41:22.492+0000",
                    "updated": "2015-11-09T19:41:22.492+0000"
                },
                {
                    "self": "$jiraServer/rest/api/2/issue/320391/comment/833460",
                    "id": "833460",
                    "author": {
                        "self": "$jiraServer/rest/api/2/user?username=fanno",
                        "name": "fanno",
                        "key": "fanno",
                        "emailAddress": "fannoj at gmail dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=fanno&avatarId=78570",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=fanno&avatarId=78570",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=fanno&avatarId=78570",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=fanno&avatarId=78570"
                        },
                        "displayName": "Morten Hundevad",
                        "active": true,
                        "timeZone": "Europe/Berlin"
                    },
                    "body": "Who is \"we\" ",
                    "updateAuthor": {
                        "self": "$jiraServer/rest/api/2/user?username=fanno",
                        "name": "fanno",
                        "key": "fanno",
                        "emailAddress": "fannoj at gmail dot com",
                        "avatarUrls": {
                            "48x48": "$jiraServer/secure/useravatar?ownerId=fanno&avatarId=78570",
                            "24x24": "$jiraServer/secure/useravatar?size=small&ownerId=fanno&avatarId=78570",
                            "16x16": "$jiraServer/secure/useravatar?size=xsmall&ownerId=fanno&avatarId=78570",
                            "32x32": "$jiraServer/secure/useravatar?size=medium&ownerId=fanno&avatarId=78570"
                        },
                        "displayName": "Morten Hundevad",
                        "active": true,
                        "timeZone": "Europe/Berlin"
                    },
                    "created": "2015-11-27T06:48:08.068+0000",
                    "updated": "2015-11-27T06:48:08.068+0000"
                }
            ]
        }
    },
    "transitions": [
        {
            "id": "1",
            "name": "Fake Transition",
            "to": {
                "self": "$jiraServer/images/icons/statuses/open.png",
                "name": "Open",
                "id": "1",
                "statusCategory": {
                    "self": "$jiraServer/rest/api/2/statuscategory/2",
                    "id": 2,
                    "key": "new",
                    "colorName": "blue-gray",
                    "name": "To Do"
                }
            }
        }
    ]
}
"@
        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        Context "Basic behavior testing" {
            $r = ConvertTo-JiraIssue -InputObject $sampleObject

            It "Creates a PSObject out of JSON input" {
                $r | Should Not BeNullOrEmpty
            }

            checkPsType $r 'JiraPS.Issue'

            defProp $r 'Key' 'JRA-37294'
            defProp $r 'Id' '320391'
            defProp $r 'RestUrl' "$jiraServer/rest/api/latest/issue/320391"
            defProp $r 'HttpUrl' "$jiraServer/browse/JRA-37294"
            defProp $r 'Summary' 'Allow set active/inactive via REST API'
            It "Defines the 'Attachment' property" {
                $r.Attachment | Should Not BeNullOrEmpty
            }
        }

        Context "Output formatting" {

            # Other ConvertTo-Jira* functions call each other in some cases, so
            # we need to mock out a few others to avoid our Assert-MockCalled
            # counts being unexpected.

            #            Mock ConvertTo-JiraComment -ModuleName JiraPS { $InputObject }
            #            Mock ConvertTo-JiraProject -ModuleName JiraPS { $InputObject }
            #            Mock ConvertTo-JiraTransition -ModuleName JiraPS { $InputObject }
            #            Mock ConvertTo-JiraUser -ModuleName JiraPS { $InputObject }

            $r = ConvertTo-JiraIssue -InputObject $sampleObject

            It "Defines Date fields as Date objects" {
                $dateFields = @('Created', 'Updated') # LastViewed should be in here too, but in this example issue from Atlassian, that value is null
                foreach ($f in $dateFields) {
                    $value = $r.$f
                    $value | Should Not BeNullOrEmpty
                    checkType $value 'System.DateTime'
                }
            }

            It "Uses ConvertTo-JiraUser to return user fields as User objects" {
                $userFields = @('Creator', 'Reporter') # Again, Assigned is another user field, but in this example it's unassigned
                foreach ($f in $userFields) {
                    $value = $r.$f
                    $value | Should Not BeNullOrEmpty
                    # (Get-Member -InputObject $value).TypeName | Should Be 'JiraPS.User'
                    checkType $value 'JiraPS.User'
                }

                # We can't mock this out without rewriting most of the code in it
                # Assert-MockCalled -CommandName ConvertTo-JiraUser -Scope Context -Exactly -Times ($userFields.Count)
            }

            It "Uses ConvertTo-JiraProject to return the project as an object" {
                # (Get-Member -InputObject $r.Project).TypeName | Should Be 'JiraPS.Project'
                checkType $r.Project 'JiraPS.Project'
            }

            It "Uses ConvertTo-JiraTransition to return the issue's transitions as an object" {
                checkType $r.Transition[0] 'JiraPS.Transition'
            }

            It "Uses ConvertTo-JiraAttachment to return the issue's attachments as an object" {
                checkType $r.Attachment 'JiraPS.Attachment'
            }
        }
    }
}
