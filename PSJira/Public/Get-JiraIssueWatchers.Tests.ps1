$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "Get-JiraIssueWatchers" {

        $ShowMockData = $false

        $jiraServer = 'http://jiraserver.example.com'
        $issueID = 41701
        $issueKey = 'IT-3676'

        ## Sample straight from the API:
        ##    https://docs.atlassian.com/jira/REST/cloud/#api/2/issue-getIssueWatchers            
        $restResult = @"
{
    "self": "http://www.example.com/jira/rest/api/2/issue/EX-1/watchers",
    "isWatching": false,
    "watchCount": 1,
    "watchers": [
        {
            "self": "http://www.example.com/jira/rest/api/2/user?username=fred",
            "name": "fred",
            "displayName": "Fred F. User",
            "active": false
        }
    ]
}
"@
        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue -ModuleName PSJira {
            [PSCustomObject] @{
                ID = $issueID;
                Key = $issueKey;
                RestUrl = "$jiraServer/rest/api/latest/issue/$issueID";
            }
        }

        # Obtaining watchers from an issue...this is IT-3676 in the test environment
        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/issue/$issueID/watchers"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json2 -InputObject $restResult
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName PSJira {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

#        Mock Write-Debug {
#            Write-Host "DEBUG: $Message" -ForegroundColor Yellow
#        }

        #############
        # Tests
        #############

        It "Obtains all Jira watchers from a Jira issue if the issue key is provided" {
            $watchers = Get-JiraIssueWatchers -Issue $issueKey
            $watchers | Should Not BeNullOrEmpty
            @($watchers).Count | Should Be 1
            $watchers.name | Should Be "fred"
            $watchers.self | Should Be "$jiraServer/rest/api/2/user?username=fred"

            # Get-JiraIssue should be called to identify the -Issue parameter
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 1 -Scope It

            # Normally, this would be called once in Get-JiraIssue and a second time in Get-JiraIssueWatchers, but
            # since we've mocked Get-JiraIssue out, it will only be called once.
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Obtains all Jira watchers from a Jira issue if the Jira object is provided" {
            $issue = Get-JiraIssue -Key $issueKey
            $watchers = Get-JiraIssueWatchers -Issue $issue
            $watchers | Should Not BeNullOrEmpty
            $watchers.name | Should Be "fred"
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Handles pipeline input from Get-JiraIssue" {
            $watchers = Get-JiraIssue -Key $issueKey | Get-JiraIssueWatchers
            $watchers | Should Not BeNullOrEmpty
            $watchers.name | Should Be "fred"
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }
    }
}


