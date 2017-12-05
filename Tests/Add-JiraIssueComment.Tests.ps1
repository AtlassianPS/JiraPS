. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'
    $issueID = 41701
    $issueKey = 'IT-3676'

    $restResponse = @"
{
    "self": "$jiraServer/rest/api/2/issue/$issueID/comment/90730",
    "id": "90730",
    "body": "Test comment",
    "created": "2015-05-01T16:24:38.000-0500",
    "updated": "2015-05-01T16:24:38.000-0500"
}
"@

    Describe "Add-JiraIssueComment" {

        if ($ShowDebugText) {
            Mock "Write-Debug" {
                Write-Output "       [DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraConfigServer {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue {
            [PSCustomObject] @{
                ID      = $issueID
                Key     = $issueKey
                RestUrl = "$jiraServer/rest/api/latest/issue/$issueID"
            }
        }

        Mock Invoke-JiraMethod -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/latest/issue/$issueID/comment"} {
            if ($ShowMockData) {
                Write-Output "       Mocked Invoke-JiraMethod with POST method" -ForegroundColor Cyan
                Write-Output "         [Method] $Method" -ForegroundColor Cyan
                Write-Output "         [URI]    $URI" -ForegroundColor Cyan
            }

            # This data was created from a GUI REST client, then sanitized. A lot of extra data was also removed to save space.
            # Many Bothans died to bring us this information.
            ConvertFrom-Json2 $restResponse
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod {
            Write-Output "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Output "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Output "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Adds a comment to an issue in JIRA" {
            $commentResult = Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey
            $commentResult | Should Not BeNullOrEmpty

            # Get-JiraIssue should be used to identify the issue parameter
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It

            # Invoke-JiraMethod should be used to add the comment
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        It "Accepts pipeline input from Get-JiraIssue" {
            $commentResult = Get-JiraIssue -InputObject $issueKey | Add-JiraIssueComment -Comment 'This is a test comment from Pester, using the pipeline!'
            $commentResult | Should Not BeNullOrEmpty

            # Get-JiraIssue should be called once here, and once inside Add-JiraIssueComment (to identify the InputObject parameter)
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        Context "Output checking" {
            Mock ConvertTo-JiraComment {}
            Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey | Out-Null


            It "Uses ConvertTo-JiraComment to beautify output" {
                Assert-MockCalled 'ConvertTo-JiraComment'
            }
        }
    }
}
