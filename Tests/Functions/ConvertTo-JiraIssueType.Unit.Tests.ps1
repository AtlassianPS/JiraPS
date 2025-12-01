#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "ConvertTo-JiraIssueType" -Tag 'Unit' {

    BeforeAll {
        . "$PSScriptRoot/../../Tests/Helpers/Resolve-ModuleSource.ps1"
        $moduleToTest = Resolve-ModuleSource
        Import-Module $moduleToTest -Force
    }
    AfterAll {
        Remove-Module JiraPS -ErrorAction SilentlyContinue
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'

        $issueTypeId = 2
        $issueTypeName = 'Test Issue Type'
        $issueTypeDescription = 'A test issue used for...well, testing'

        $sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/issuetype/2",
    "id": "$issueTypeId",
    "description": "$issueTypeDescription",
    "iconUrl": "$jiraServer/images/icons/issuetypes/newfeature.png",
    "name": "$issueTypeName",
    "subtask": false
}
"@
        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        $r = ConvertTo-JiraIssueType $sampleObject
        It "Creates a PSObject out of JSON input" {
            $r | Should -Not -BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.IssueType'

        defProp $r 'Id' $issueTypeId
        defProp $r 'Name' $issueTypeName
        defProp $r 'Description' $issueTypeDescription
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/issuetype/$issueTypeId"
        defProp $r 'IconUrl' "$jiraServer/images/icons/issuetypes/newfeature.png"
        defProp $r 'Subtask' $false
    }
}
