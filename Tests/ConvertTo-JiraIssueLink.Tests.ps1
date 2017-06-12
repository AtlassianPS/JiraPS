. $PSScriptRoot\Shared.ps1
InModuleScope PSJira {
    Describe "ConvertTo-JiraIssueLink" {
        . $PSScriptRoot\Shared.ps1

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

        checkPsType $r 'PSJira.IssueLink'

        defProp $r 'Id' $issueLinkId
        defProp $r 'Type' "@{OutwardText=composes; InwardText=is part of; Name=Composition; ID=10500; RestUrl=}"
        defProp $r 'InwardIssue' "[$issueKeyInward] "
        defProp $r 'OutwardIssue' "[$issueKeyOutward] "

        It "Handles pipeline input" {
            $r = $sampleObject | ConvertTo-JiraIssueLink
            @($r).Count | Should Be 1
        }
    }
}
