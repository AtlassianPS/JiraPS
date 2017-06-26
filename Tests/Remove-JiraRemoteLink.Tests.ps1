. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    # This is intended to be a parameter to the test, but Pester currently does not allow parameters to be passed to InModuleScope blocks.
    # For the time being, we'll need to hard-code this and adjust it as desired.
    $ShowMockData = $false
    $ShowDebugData = $false

    $jiraServer = 'http://jiraserver.example.com'

    $testIssueKey = 'EX-1'

    $testLink = @"
{
    "id": 10000,
    "self": "http://www.example.com/jira/rest/api/issue/MKY-1/remotelink/10000",
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

    Describe "Remove-JiraRemoteLink" {

        Mock Write-Debug -ModuleName JiraPS {
            if ($ShowDebugData) {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue {
            [PSCustomObject] @{
                'RestURL' = 'https://jira.example.com/rest/api/2/issue/12345'
                'Key'     = $testIssueKey
            }
        }

        Mock Get-JiraRemoteLink {
            ConvertFrom-Json2 $testLink
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'DELETE'} {
            if ($ShowMockData) {
                Write-Host "       Mocked Invoke-JiraMethod with DELETE method" -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
            # This REST method should produce no output
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Accepts a issue key to the -Issue parameter" {
            { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts a JiraPS.Issue object to the -Issue parameter" {
            $Issue = Get-JiraIssue $testIssueKey
            { Remove-JiraRemoteLink -Issue $Issue -LinkId 10000 -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts pipeline input from Get-JiraIssue" {
            { Get-JiraIssue $testIssueKey | Remove-JiraRemoteLink -LinkId 10000 -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts the output of Get-JiraRemoteLink" {
            $remoteLink = Get-JiraRemoteLink $testIssueKey
            { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId $remoteLink.id -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Removes a group from JIRA" {
            { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Provides no output" {
            Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force | Should BeNullOrEmpty
        }
    }
}
