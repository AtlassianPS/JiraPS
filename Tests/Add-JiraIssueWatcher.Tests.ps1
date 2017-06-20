$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $ShowMockData = $false

    $jiraServer = 'http://jiraserver.example.com'
    $issueID = 41701
    $issueKey = 'IT-3676'

    Describe "Add-JiraIssueWatcher" {

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

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/latest/issue/$issueID/watchers"} {
            if ($ShowMockData) {
                Write-Host "       Mocked Invoke-JiraMethod with POST method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName PSJira {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Adds a Watcher to an issue in JIRA" {
            $WatcherResult = Add-JiraIssueWatcher -Watcher 'fred' -Issue $issueKey
            $WatcherResult | Should BeNullOrEmpty

            # Get-JiraIssue should be used to identiyf the issue parameter
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 1 -Scope It

            # Invoke-JiraMethod should be used to add the Watcher
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Accepts pipeline input from Get-JiraIssue" {
            $WatcherResult = Get-JiraIssue -InputObject $issueKey | Add-JiraIssueWatcher -Watcher 'fred'
            $WatcherResult | Should BeNullOrEmpty

            # Get-JiraIssue should be called once here, and once inside Add-JiraIssueWatcher (to identify the InputObject parameter)
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 2 -Scope It
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }
    }
}
