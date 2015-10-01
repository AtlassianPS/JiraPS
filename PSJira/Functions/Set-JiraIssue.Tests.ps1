$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    # This is intended to be a parameter to the test, but Pester currently does not allow parameters to be passed to InModuleScope blocks.
    # For the time being, we'll need to hard-code this and adjust it as desired.
    $ShowMockData = $false

    Describe "Set-JiraIssue" {

        $jiraServer = 'http://jiraserver.example.com'
        $issueID = 41701
        $issueKey = 'IT-3676'

        $testUsername = 'powershell-test'

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue -ModuleName PSJira {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Get-JiraIssue" -ForegroundColor Cyan
                Write-Host "         [Key]         $Key" -ForegroundColor Cyan
                Write-Host "         [InputObject] $InputObject" -ForegroundColor Cyan
            }

            [PSCustomObject] @{
                Summary     = 'Test issue';
                Description = 'Test issue from PowerShell';
                Key         = $issueKey;
                RestURL     = "$jiraServer/rest/api/latest/issue/$issueID";
            }
        }

        Mock Get-JiraUser -ModuleName PSJira {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Get-JiraUser" -ForegroundColor Cyan
                Write-Host "         [UserName]    $UserName" -ForegroundColor Cyan
                Write-Host "         [InputObject] $InputObject" -ForegroundColor Cyan
            }

            [PSCustomObject] @{
                Name = 'powershell-test';
            }
        }

        Mock Get-JiraIssue -ModuleName PSJira {
            [PSCustomObject] @{
                ID = $issueID;
                Key = $issueKey;
                RestUrl = "$jiraServer/rest/api/latest/issue/$issueID";
            }
        }

        # Edit issue
        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Put' -and $URI -eq "$jiraServer/rest/api/latest/issue/$issueId"} {
            # If successful, Jira will return a 204, so no output should be produced here.
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with PUT method." -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
        }

        # Assign issue
        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Put' -and $URI -eq "$jiraServer/rest/api/latest/issue/$issueId/assignee"} {
            # If successful, Jira will return a 204, so no output should be produced here.
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with PUT method." -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
        }

        Mock Invoke-JiraMethod -ModuleName PSJira {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        It "Accepts an issue key for the -Issue parameter" {
            { Set-JiraIssue -Issue $issueKey -Summary 'Test summary - Key' -Description 'This is a test of key input using the parameter directly.'} | Should Not Throw
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Accepts an issue object for the -Issue parameter" {
            $issue = Get-JiraIssue -Key $issueKey
            { Set-JiraIssue -Issue $issue -Summary 'Test summary - Object' -Description 'This is a test input using an object variable.' } | Should Not Throw
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 2 -Scope It
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Accepts the output of Get-JiraObject by pipeline for the -Issue paramete" {
            { Get-JiraIssue -Key $issueKey | Set-JiraIssue -Summary 'Test summary - InputObject pipeline' -Description 'This is a test InputObject input using the pipeline.'} | Should Not Throw
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 2 -Scope It
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Edits the summary and description of an issue" {
            { Set-JiraIssue -Key $issueKey -Summary 'Test summary - IssueKey' -Description 'This is a test of editing the summary field.' } | Should Not Throw
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Assigns the issue" {
            { Set-JiraIssue -Key $issueKey -Assignee $testUsername } | Should Not Throw

            # Should use Get-JiraUser to obtain Assignee
            Assert-MockCalled -CommandName Get-JiraUser -ModuleName PSJira -Exactly -Times 1 -Scope It

            # Should use Get-JiraIssue to obtain issue
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 1 -Scope It

            # Should use Invoke-JiraMethod to update issue
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Unassigns the issue if the -Assignee parameter is supplied with 'Unassigned'" {
            { Set-JiraIssue -Key $issueKey -Assignee 'Unassigned' } | Should Not Throw

            # Get-JiraUser should NOT be called for the 'Unassigned' user
            Assert-MockCalled -CommandName Get-JiraUser -ModuleName PSJira -Exactly -Times 0 -Scope It

            # Should use Get-JiraIssue to obtain issue
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 1 -Scope It

            # Should use Invoke-JiraMethod to update issue
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Edits the issue and assigns the issue if both parameters are supplied" {
            { Set-JiraIssue -Key $issueKey -Summary 'Test summary - IssueKey and Assignee' -Description 'This is a test of editing multiple fields at once.' -Assignee $testUsername } | Should Not Throw

            # Should use Get-JiraUser to obtain Assignee
            Assert-MockCalled -CommandName Get-JiraUser -ModuleName PSJira -Exactly -Times 1 -Scope It

            # Should use Get-JiraIssue to obtain issue
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 1 -Scope It

            # Should use two separate calls to Invoke-JiraMethod to update issue and assign issue
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 2 -Scope It
        }
    }
}


