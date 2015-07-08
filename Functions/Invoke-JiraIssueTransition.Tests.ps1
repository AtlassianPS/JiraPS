$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    
    # This is intended to be a parameter to the test, but Pester currently does not allow parameters to be passed to InModuleScope blocks.
    # For the time being, we'll need to hard-code this and adjust it as desired.
    $ShowMockData = $false
    
    $jiraServer = 'http://jiraserver.example.com'
    $issueID = 41701
    $issueKey = 'IT-3676'

    Describe "Invoke-JiraIssueTransition" {
        
        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }
        
        Mock Get-JiraIssue -ModuleName PSJira {
            $t1 = [PSCustomObject] @{
                Name = 'Start Progress';
                ID   = 11;
            }
            $t1.PSObject.TypeNames.Insert(0, 'PSJira.Transition')
            $t2 = [PSCustomObject] @{
                Name = 'Resolve';
                ID   = 81;
            }
            $t2.PSObject.TypeNames.Insert(0, 'PSJira.Transition')

            [PSCustomObject] @{
                ID = $issueID;
                Key = $issueKey;
                RestUrl = "$jiraServer/rest/api/latest/issue/$issueID";
                Transition = @($t1,$t2)
            }
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Post' -and $URI -eq "$jiraServer/rest/api/latest/issue/$issueID/transitions"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with POST method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            # This should return a 204 status code, so no data should actually be returned
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
#
        #############
        # Tests
        #############

        It "Performs a transition on a Jira issue when given an issue key and transition ID" {
            { $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 } | Should Not Throw
            Assert-MockCalled Get-JiraIssue -ModuleName PSJira -Exactly -Times 1 -Scope It
            Assert-MockCalled Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Performs a transition on a Jira issue when given an issue object and transition object" {
            $issue = Get-JiraIssue -Key $issueKey
            $transition = $issue.Transition[0]
            { Invoke-JiraIssueTransition -Issue $issue -Transition $transition } | Should Not Throw
            # Get-JiraIssue should be called once here in the test, and once in Invoke-JiraIssueTransition to 
            # obtain a reference to the issue object
            Assert-MockCalled Get-JiraIssue -ModuleName PSJira -Exactly -Times 2 -Scope It
            Assert-MockCalled Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Handles pipeline input from Get-JiraIssue" {
            { $result = Get-JiraIssue -Key $issueKey | Invoke-JiraIssueTransition -Transition 11 } | Should Not Throw
            Assert-MockCalled Get-JiraIssue -ModuleName PSJira -Exactly -Times 2 -Scope It
            Assert-MockCalled Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }
    }
}