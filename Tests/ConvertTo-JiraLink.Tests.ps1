. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "ConvertTo-JiraLink" {

        $jiraServer = 'http://jiraserver.example.com'
        $LinkID = "10000"

        $sampleJson = @"
{
    "id": 10000,
    "self": "http://jiraserver.example.com/rest/api/issue/MKY-1/remotelink/10000",
    "globalId": "system=http://www.mycompany.com/support&id=1",
    "application": {
        "type": "com.acme.tracker",
        "name": "My Acme Tracker"
    },
    "relationship": "causes",
    "object": {
        "url": "http://www.mycompany.com/support?id=1",
        "title": "TSTSUP-111",
        "summary": "Crazy customer support issue",
        "icon": {
            "url16x16": "http://www.mycompany.com/support/ticket.png",
            "title": "Support Ticket"
        },
        "status": {
            "resolved": true,
            "icon": {
                "url16x16": "http://www.mycompany.com/support/resolved.png",
                "title": "Case Closed",
                "link": "http://www.mycompany.com/support?id=1&details=closed"
            }
        }
    }
}
"@
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        $r = ConvertTo-JiraLink -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.Link'

        defProp $r 'id' $LinkId
        defProp $r 'RestUrl' "$jiraServer/rest/api/issue/MKY-1/remotelink/10000"
    }
}
