. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {
    Describe "ConvertTo-JiraGroup" {
        . $PSScriptRoot\Shared.ps1

        $jiraServer = 'http://jiraserver.example.com'
        $groupName = 'powershell-testgroup'

        $sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/group?groupname=$groupName",
    "name": "$groupName",
    "users": {
        "size": 1,
        "items": [],
        "max-results": 50,
        "start-index": 0,
        "end-index": 0
    },
    "expand": "users"
}
"@
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        $r = ConvertTo-JiraGroup -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'PSJira.Group'

        defProp $r 'Name' $groupName
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/group?groupname=$groupName"
        defProp $r 'Size' 1
    }
}
