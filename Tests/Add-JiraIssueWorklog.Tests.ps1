. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    $ShowMockData = $false

    $jiraServer = 'http://jiraserver.example.com'
    $jiraUsername = 'powershell-test'
    $jiraUserDisplayName = 'PowerShell Test User'
    $jiraUserEmail = 'noreply@example.com'
    $issueID = 41701
    $issueKey = 'IT-3676'
    $worklogitemID = 73040

    $restResponse = @"
{
    "id": "$worklogitemID",
    "self": "$jiraServer/rest/api/latest/issue/$issueID/worklog/$worklogitemID",
    "comment": "Test description",
    "created": "2015-05-01T16:24:38.000-0500",
    "updated": "2015-05-01T16:24:38.000-0500",
    "started": "2017-02-23T22:21:00.000-0500",
    "timeSpent": "1h",
    "timeSpentSeconds": "3600",
    "author": {
        "self": "$jiraServer/rest/api/2/user?username=powershell-test",
        "name": "$jiraUsername",
        "emailAddress": "$jiraUserEmail",
        "avatarUrls": {
            "48x48": "$jiraServer/secure/useravatar?avatarId=10202",
            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10202",
            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10202",
            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10202"
        },
        "displayName": "$jiraUserDisplayName",
        "active": true
    },
    "updateAuthor": {
        "self": "$jiraServer/rest/api/2/user?username=powershell-test",
        "name": "powershell-test",
        "emailAddress": "$jiraUserEmail",
        "avatarUrls": {
            "48x48": "$jiraServer/secure/useravatar?avatarId=10202",
            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10202",
            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10202",
            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10202"
        },
        "displayName": "$jiraUserDisplayName",
        "active": true
    }
}
"@

    Describe "Add-JiraIssueWorklog" {

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            $result = [PSCustomObject] @{
                ID      = $issueID;
                Key     = $issueKey;
                RestUrl = "$jiraServer/rest/api/latest/issue/$issueID";
            }
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            Write-Output $result
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/latest/issue/$issueID/worklog"} {
            if ($ShowMockData) {
                Write-Host "       Mocked Invoke-JiraMethod with POST method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }

            # This data was created from a GUI REST client, then sanitized. A lot of extra data was also removed to save space.
            # Many Bothans died to bring us this information.
            ConvertFrom-Json2 $restResponse
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

        It "Adds a worklog item to an issue in JIRA" {
            $commentResult = Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent 3600 -DateStarted "2018-01-01"
            $commentResult | Should Not BeNullOrEmpty

            # Get-JiraIssue should be used to identify the issue parameter
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It

            # Invoke-JiraMethod should be used to add the comment
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        It "Accepts pipeline input from Get-JiraIssue" {
            $commentResult = Get-JiraIssue -InputObject $issueKey | Add-JiraIssueWorklog -Comment 'This is a test worklog item from Pester, using the pipeline!' -TimeSpent "3600" -DateStarted "2018-01-01"
            $commentResult | Should Not BeNullOrEmpty

            # Get-JiraIssue should be called once here to fetch the initial test issue
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }
    }
}
