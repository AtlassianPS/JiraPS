Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

InModuleScope JiraPS {
    . "$PSScriptRoot/Shared.ps1"

    $jiraServer = 'https://jiraserver.example.com'

    $issueKey = 'MKY-1'

    $restResult = @"
{
    "id": 10000,
    "self": "$jiraServer/rest/api/latest/issue/MKY-1/remotelink/10000",
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
        }
    }
}
"@

    Describe "Get-JiraRemoteLink" {

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue {
            $object = [PSCustomObject] @{
                'RestURL' = "$jiraServer/rest/api/latest/issue/12345"
                'Key'     = $issueKey
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        Mock Resolve-JiraIssueObject -ModuleName JiraPS {
            Get-JiraIssue -Key $Issue
        }

        Mock ConvertTo-JiraIssueLinkType -ModuleName JiraPS {
            $InputObject
        }

        # Searching for a group.
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get'} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json2 -InputObject $restResult
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Gets information of all remote link from a Jira issue" {
            $getResult = Get-JiraRemoteLink -Issue $issueKey
            $getResult | Should Not BeNullOrEmpty

            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {$Method -eq "Get" -and $Uri -like "$jiraServer/rest/api/*/issue/12345/remotelink"}
        }

        It "Gets information of all remote link from a Jira issue" {
            $getResult = Get-JiraRemoteLink -Issue $issueKey -LinkId 10000
            $getResult | Should Not BeNullOrEmpty

            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {$Method -eq "Get" -and $Uri -like "$jiraServer/rest/api/*/issue/12345/remotelink/10000"}
        }
    }
}
