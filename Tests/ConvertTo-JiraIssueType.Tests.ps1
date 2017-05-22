. $PSScriptRoot\Shared.ps1
InModuleScope PSJira {
    Describe "ConvertTo-JiraIssueType" {
        . $PSScriptRoot\Shared.ps1

        $jiraServer = 'http://jiraserver.example.com'

        $issueTypeId = 2
        $issueTypeName = 'Test Issue Type'
        $issueTypeDescription = 'A test issue used for...well, testing'

        $sampleJson = @"
{
    "self": "$jiraServer/rest/api/latest/issuetype/2",
    "id": "$issueTypeId",
    "description": "$issueTypeDescription",
    "iconUrl": "$jiraServer/images/icons/issuetypes/newfeature.png",
    "name": "$issueTypeName",
    "subtask": false
  }
"@
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        $r = ConvertTo-JiraIssueType $sampleObject
        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'PSJira.IssueType'

        defProp $r 'Id' $issueTypeId
        defProp $r 'Name' $issueTypeName
        defProp $r 'Description' $issueTypeDescription
        defProp $r 'RestUrl' "$jiraServer/rest/api/latest/issuetype/$issueTypeId"
        defProp $r 'IconUrl' "$jiraServer/images/icons/issuetypes/newfeature.png"
        defProp $r 'Subtask' $false
    }
}
