. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {
    Describe "ConvertTo-JiraStatus" {
        . $PSScriptRoot\Shared.ps1

        $jiraServer = 'http://jiraserver.example.com'

        $statusName = 'In Progress'
        $statusId = 3
        $statusDesc = 'This issue is being actively worked on at the moment by the assignee.'

        $sampleJson = @"
{
  "self": "$jiraServer/rest/api/2/status/$statusId",
  "description": "$statusDesc",
  "iconUrl": "$jiraServer/images/icons/statuses/inprogress.png",
  "name": "$statusName",
  "id": "$statusId",
  "statusCategory": {
    "self": "$jiraServer/rest/api/2/statuscategory/4",
    "id": 4,
    "key": "indeterminate",
    "colorName": "yellow",
    "name": "In Progress"
  }
}
"@
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        $r = ConvertTo-JiraStatus -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'PSJira.Status'

        defProp $r 'Id' $statusId
        defProp $r 'Name' $statusName
        defProp $r 'Description' $statusDesc
        defProp $r 'IconUrl' "$jiraServer/images/icons/statuses/inprogress.png"
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/status/$statusId"
    }
}
