$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $ShowMockData = $false

    $jiraServer = 'http://jiraserver.example.com'
    $issueID = 41701
    $issueKey = 'IT-3676'

    $restResponse = @"
{
  "expand": "renderedFields,names,schema,transitions,operations,editmeta,changelog",
  "id": "$issueID",
  "self": "$jiraServer/rest/api/latest/issue/$issueID",
  "key": "$issueKey",
  "fields": {
    "description": "Test issue from PowerShell (created at an interactive shell).",
    "comment": {
      "startAt": 0,
      "maxResults": 1,
      "total": 1,
      "comments": [
        {
          "self": "$jiraServer/rest/api/2/issue/$issueID/comment/90730",
          "id": "90730",
          "body": "Test comment",
          "created": "2015-05-01T16:24:38.000-0500",
          "updated": "2015-05-01T16:24:38.000-0500"
        }
      ]
    }
  }
}
"@

    Describe "Add-JiraIssueComment" {

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

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/latest/issue/$issueID/comment"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with POST method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }

            # This data was created from a GUI REST client, then sanitized. A lot of extra data was also removed to save space.
            # Many Bothans died to bring us this information.
            ConvertFrom-Json2 $restResponse
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

        It "Adds a comment to an issue in JIRA" {
            $commentResult = Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey
            $commentResult | Should Not BeNullOrEmpty

            # Get-JiraIssue should be used to identiyf the issue parameter
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 1 -Scope It

            # Invoke-JiraMethod should be used to add the comment
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Accepts pipeline input from Get-JiraIssue" {
            $commentResult = Get-JiraIssue -InputObject $issueKey | Add-JiraIssueComment -Comment 'This is a test comment from Pester, using the pipeline!'
            $commentResult | Should Not BeNullOrEmpty

            # Get-JiraIssue should be called once here, and once inside Add-JiraIssueComment (to identify the InputObject parameter)
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 2 -Scope It
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Outputs the comment as a PSJira.Comment object" {
            $commentResult = Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey
            (Get-Member -InputObject $commentResult).TypeName | Should Be 'PSJira.Comment'
        }
    }
}


