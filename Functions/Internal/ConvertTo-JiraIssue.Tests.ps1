$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    Describe "ConvertTo-JiraIssue" {

        function defProp($obj, $propName, $propValue)
        {
            It "Defines the '$propName' property" {
                $obj.$propName | Should Be $propValue
            }
        }

        $jiraServer = 'http://jiraserver.example.com'
    
        $issueID = 41701
        $issueKey = 'IT-3676'
        $issueSummary = 'Test issue'
        $issueDescription = 'Test issue from PowerShell'

        $sampleJson = @"
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
    "description": "$issueDescription",
    "project": {
        "self": "$jiraServer/rest/api/2/project/10003",
        "id": "10003",
        "key": "IT",
        "name": "Information Technology"
    },
    "customfield_10012": ".",
    "summary": "$issueSummary",
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

        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        $r = ConvertTo-JiraIssue -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }
    
        It "Sets the type name to PSJira.Issue" {
    #        $r.PSObject.TypeNames[0] | Should Be 'PSJira.Issue'
            (Get-Member -InputObject $r).TypeName | Should Be 'PSJira.Issue'
        }

        defProp $r 'Key' $issueKey
        defProp $r 'Id' $issueID
        defProp $r 'RestUrl' "$jiraServer/rest/api/latest/issue/$issueID"
        defProp $r 'HttpUrl' "$jiraServer/browse/$issueKey"
        defProp $r 'Summary' $issueSummary
        defProp $r 'Description' $issueDescription
    }
}