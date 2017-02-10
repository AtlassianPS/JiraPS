$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "ConvertTo-JiraFilter" {
        function defProp($obj, $propName, $propValue)
        {
            It "Defines the '$propName' property" {
                $obj.$propName | Should Be $propValue
            }
        }

        # Obtained from Atlassian's public JIRA instance
        $sampleJson = @'
{
    "self": "https://jira.atlassian.com/rest/api/latest/filter/12844",
    "id": "12844",
    "name": "All JIRA Bugs",
    "owner": {
        "self": "https://jira.atlassian.com/rest/api/2/user?username=scott@atlassian.com",
        "key": "scott@atlassian.com",
        "name": "scott@atlassian.com",
        "avatarUrls": {
            "16x16": "https://jira.atlassian.com/secure/useravatar?size=xsmall&avatarId=10612",
            "24x24": "https://jira.atlassian.com/secure/useravatar?size=small&avatarId=10612",
            "32x32": "https://jira.atlassian.com/secure/useravatar?size=medium&avatarId=10612",
            "48x48": "https://jira.atlassian.com/secure/useravatar?avatarId=10612"
        },
        "displayName": "Scott Farquhar [Atlassian]",
        "active": true
    },
    "jql": "project = 10240 AND issuetype = 1 ORDER BY key DESC",
    "viewUrl": "https://jira.atlassian.com/secure/IssueNavigator.jspa?mode=hide&requestId=12844",
    "searchUrl": "https://jira.atlassian.com/rest/api/latest/search?jql=project+%3D+10240+AND+issuetype+%3D+1+ORDER+BY+key+DESC",
    "favourite": false,
    "sharePermissions": [
        {
            "id": 10049,
            "type": "global"
        }
    ],
    "sharedUsers": {
        "size": 0,
        "items": [],
        "max-results": 1000,
        "start-index": 0,
        "end-index": 0
    },
    "subscriptions": {
        "size": 0,
        "items": [],
        "max-results": 1000,
        "start-index": 0,
        "end-index": 0
    }
}
'@

        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        It "Creates a PSObject out of JSON input" {
            $r = ConvertTo-JiraFilter -InputObject $sampleObject
            $r | Should Not BeNullOrEmpty
        }

        It "Sets the type name to PSJira.Filter" {
            $r = ConvertTo-JiraFilter -InputObject $sampleObject
            $r | Test-HasTypeName 'PSJira.Filter' | Should Be $True
        }

        $r = ConvertTo-JiraFilter -InputObject $sampleObject

        defProp $r 'Id' 12844
        defProp $r 'Name' 'All JIRA Bugs'
        defProp $r 'JQL' 'project = 10240 AND issuetype = 1 ORDER BY key DESC'
        defProp $r 'RestUrl' 'https://jira.atlassian.com/rest/api/latest/filter/12844'
        defProp $r 'ViewUrl' 'https://jira.atlassian.com/secure/IssueNavigator.jspa?mode=hide&requestId=12844'
        defProp $r 'SearchUrl' 'https://jira.atlassian.com/rest/api/latest/search?jql=project+%3D+10240+AND+issuetype+%3D+1+ORDER+BY+key+DESC'
        defProp $r 'Favorite' $false

    }
}


