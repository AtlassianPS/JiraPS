Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

InModuleScope JiraPS {
    . "$PSScriptRoot/Shared.ps1"

    Describe "ConvertTo-JiraIssueLink" {

        $jiraServer = 'http://jiraserver.example.com'

        $issueLinkId = 41313
        $issueKeyInward = "TEST-01"
        $issueKeyOutward = "TEST-10"
        $linkTypeName = "Composition"

        $sampleJson = @"
{
    "id": "$issueLinkId",
    "type": {
        "id": "10500",
        "name": "$linkTypeName",
        "inward": "is part of",
        "outward": "composes"
    },
    "inwardIssue": {
        "key": "$issueKeyInward"
    },
    "outwardIssue": {
        "key": "$issueKeyOutward"
    }
}
"@

        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        $r = ConvertTo-JiraIssueLink -InputObject $sampleObject
        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.IssueLink'

        defProp $r 'Id' $issueLinkId
        defProp $r 'Type' "Composition"
        defProp $r 'InwardIssue' "[$issueKeyInward] "
        defProp $r 'OutwardIssue' "[$issueKeyOutward] "

        It "Handles pipeline input" {
            $r = $sampleObject | ConvertTo-JiraIssueLink
            @($r).Count | Should Be 1
        }
    }
}
