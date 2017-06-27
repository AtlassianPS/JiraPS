. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'
    $issueID = 41701
    $issueKey = 'IT-3676'

    Describe "Invoke-JiraIssueTransition" {

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            $t1 = [PSCustomObject] @{
                Name = 'Start Progress';
                ID   = 11;
            }
            $t1.PSObject.TypeNames.Insert(0, 'JiraPS.Transition')
            $t2 = [PSCustomObject] @{
                Name = 'Resolve';
                ID   = 81;
            }
            $t2.PSObject.TypeNames.Insert(0, 'JiraPS.Transition')

            [PSCustomObject] @{
                ID         = $issueID;
                Key        = $issueKey;
                RestUrl    = "$jiraServer/rest/api/latest/issue/$issueID";
                Transition = @($t1, $t2)
            }
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Post' -and $URI -eq "$jiraServer/rest/api/latest/issue/$issueID/transitions"} {
            if ($ShowMockData) {
                Write-Host "       Mocked Invoke-JiraMethod with POST method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            # This should return a 204 status code, so no data should actually be returned
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        # Mock Write-Debug {
        #     Write-Host "DEBUG: $Message" -ForegroundColor Yellow
        # }
        #
        #############
        # Tests
        #############

        It "Performs a transition on a Jira issue when given an issue key and transition ID" {
            { $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 } | Should Not Throw
            Assert-MockCalled Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It
            Assert-MockCalled Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        It "Performs a transition on a Jira issue when given an issue object and transition object" {
            $issue = Get-JiraIssue -Key $issueKey
            $transition = $issue.Transition[0]
            { Invoke-JiraIssueTransition -Issue $issue -Transition $transition } | Should Not Throw
            # Get-JiraIssue should be called once here in the test, and once in Invoke-JiraIssueTransition to
            # obtain a reference to the issue object
            Assert-MockCalled Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
            Assert-MockCalled Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        It "Handles pipeline input from Get-JiraIssue" {
            { $result = Get-JiraIssue -Key $issueKey | Invoke-JiraIssueTransition -Transition 11 } | Should Not Throw
            Assert-MockCalled Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
            Assert-MockCalled Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }


        It "Updates custom fields if provided to the -Fields parameter" {
            Mock Get-JiraField {
                [PSCustomObject] @{
                    'Name' = $Field;
                    'ID'   = $Field;
                }
            }
            { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Fields @{'customfield_12345' = 'foo'; 'customfield_67890' = 'bar'} } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Post' -and $URI -like "*/rest/api/latest/issue/$issueID/transitions" -and $Body -like '*customfield_12345*set*foo*' }
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Post' -and $URI -like "*/rest/api/latest/issue/$issueID/transitions" -and $Body -like '*customfield_67890*set*bar*' }
        }

        It "Updates assignee name if provided to the -Assignee parameter" {
            Mock Get-JiraUser {
                [PSCustomObject] @{
                    'Name'    = 'powershell-user';
                    'RestUrl' = "$jiraServer/rest/api/2/user?username=powershell-user";
                }
            }
            { $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Assignee 'powershell-user'} | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Post' -and $URI -like "*/rest/api/latest/issue/$issueID/transitions" -and $Body -like '*name*powershell-user*' }
        }

        It "Unassigns an issue if 'Unassigned' is passed to the -Assignee parameter" {
            { $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Assignee 'Unassigned'} | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Post' -and $URI -like "*/rest/api/latest/issue/$issueID/transitions" -and $Body -like '*name*""*' }
        }

        It "Adds a comment if provide to the -Comment parameter" {
            { $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Comment 'test comment'} | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Post' -and $URI -like "*/rest/api/latest/issue/$issueID/transitions" -and $Body -like '*body*test comment*' }
        }
    }
}
