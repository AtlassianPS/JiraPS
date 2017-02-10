$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "ConvertTo-JiraIssueType" {
        function defProp($obj, $propName, $propValue)
        {
            It "Defines the '$propName' property" {
                $obj.$propName | Should Be $propValue
            }
        }

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

        It "Sets the type name to PSJira.IssueType" {
            $r | Test-HasTypeName 'PSJira.IssueType' | Should Be $True
        }

        defProp $r 'Id' $issueTypeId
        defProp $r 'Name' $issueTypeName
        defProp $r 'Description' $issueTypeDescription
        defProp $r 'RestUrl' "$jiraServer/rest/api/latest/issuetype/$issueTypeId"
        defProp $r 'IconUrl' "$jiraServer/images/icons/issuetypes/newfeature.png"
        defProp $r 'Subtask' $false
    }
}
