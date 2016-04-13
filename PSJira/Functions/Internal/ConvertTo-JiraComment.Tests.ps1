$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "ConvertTo-JiraComment" {
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

        $commentId = 90730
        $commentBody = "Test comment"

        $sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/issue/41701/comment/90730",
    "id": "$commentId",
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
    "body": "$commentBody",
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
    },
    "created": "2015-05-01T16:24:38.000-0500",
    "updated": "2015-05-01T16:24:38.000-0500",
    "visibility": {
    "type": "role",
    "value": "Developers"
    }
}
"@

        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        It "Creates a PSObject out of JSON input" {
            $r = ConvertTo-JiraComment -InputObject $sampleObject
            $r | Should Not BeNullOrEmpty
        }

        It "Sets the type name to PSJira.Comment" {
            $r = ConvertTo-JiraComment -InputObject $sampleObject
            $r.PSObject.TypeNames[0] | Should Be 'PSJira.Comment'
        }

        $r = ConvertTo-JiraComment -InputObject $sampleObject

        defProp $r 'Id' $commentId
        defProp $r 'Body' $commentBody
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/issue/41701/comment/$commentId"
        defProp $r 'Created' (Get-Date '2015-05-01T16:24:38.000-0500')
        defProp $r 'Updated' (Get-Date '2015-05-01T16:24:38.000-0500')
    }
}


