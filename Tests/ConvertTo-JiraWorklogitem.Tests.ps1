. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    Describe "ConvertTo-JiraWorklogitem" {
        function defProp($obj, $propName, $propValue)
        {
            It "Defines the '$propName' property" {
                $obj.$propName | Should Be $propValue
            }
        }

    $jiraServer = 'http://jiraserver.example.com'
    $jiraUsername = 'powershell-test'
    $jiraUserDisplayName = 'PowerShell Test User'
    $jiraUserEmail = 'noreply@example.com'
    $issueID = 41701
    $issueKey = 'IT-3676'
    $worklogitemID = 73040
    $commentBody = "Test description"
    $worklogTimeSpent = "1h"
    $worklogTimeSpentSeconds = "3600"

        $sampleJson = @"
{
  "id": "$worklogitemID",
  "self": "$jiraServer/rest/api/2/issue/$issueID/worklog/$worklogitemID",
  "comment": "Test description",
  "created": "2015-05-01T16:24:38.000-0500",
  "updated": "2015-05-01T16:24:38.000-0500",
  "started": "2017-02-23T22:21:00.000-0500",
  "timeSpent": "1h",
  "timeSpentSeconds": "3600",
  "author": {
    "self": "$jiraServer/rest/api/2/user?username=powershell-test",
    "name": "$jiraUsername",
    "emailAddress": "$jiraUserEmail",
    "avatarUrls": {
        "48x48": "$jiraServer/secure/useravatar?avatarId=10202",
        "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10202",
        "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10202",
        "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10202"
    },
    "displayName": "$jiraUserDisplayName",
    "active": true
  },
  "updateAuthor": {
    "self": "$jiraServer/rest/api/2/user?username=powershell-test",
    "name": "powershell-test",
    "emailAddress": "$jiraUserEmail",
    "avatarUrls": {
        "48x48": "$jiraServer/secure/useravatar?avatarId=10202",
        "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10202",
        "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10202",
        "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10202"
    },
    "displayName": "$jiraUserDisplayName",
    "active": true
  }
}
"@
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        It "Creates a PSObject out of JSON input" {
            $r = ConvertTo-JiraWorklogitem -InputObject $sampleObject
            $r | Should Not BeNullOrEmpty
        }

        It "Sets the type name to JiraPS.WorklogItem" {
            $r = ConvertTo-JiraWorklogitem -InputObject $sampleObject
            $r.PSObject.TypeNames[0] | Should Be 'JiraPS.WorklogItem'
        }

        $r = ConvertTo-JiraWorklogitem -InputObject $sampleObject

        defProp $r 'Id' $worklogitemID
        defProp $r 'Comment' $commentBody
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/issue/41701/worklog/$worklogitemID"
        defProp $r 'Created' (Get-Date '2015-05-01T16:24:38.000-0500')
        defProp $r 'Updated' (Get-Date '2015-05-01T16:24:38.000-0500')
        defProp $r 'Started' (Get-Date '2017-02-23T22:21:00.000-0500')
        defProp $r 'TimeSpent' $worklogTimeSpent
        defProp $r 'TimeSpentSeconds' $worklogTimeSpentSeconds
    }
}


