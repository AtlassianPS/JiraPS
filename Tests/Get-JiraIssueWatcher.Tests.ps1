﻿. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'
    $issueID = 41701
    $issueKey = 'IT-3676'

    Describe "Get-JiraIssueWatcher" {


        ## Sample straight from the API:
        ##    https://docs.atlassian.com/jira/REST/cloud/#api/2/issue-getIssueWatchers
        $restResult = @"
{
    "self": "$jiraServer/jira/rest/api/2/issue/EX-1/watchers",
    "isWatching": false,
    "watchCount": 1,
    "watchers": [
        {
            "self": "$jiraServer/jira/rest/api/2/user?username=fred",
            "name": "fred",
            "displayName": "Fred F. User",
            "active": false
        }
    ]
}
"@
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            [PSCustomObject] @{
                ID      = $issueID;
                Key     = $issueKey;
                RestUrl = "$jiraServer/rest/api/latest/issue/$issueID";
            }
        }

        # Obtaining watchers from an issue...this is IT-3676 in the test environment
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/issue/$issueID/watchers"} {
            ShowMockInfo 'Invoke-JiraMethod' -Params 'Uri', 'Method'
            ConvertFrom-Json2 -InputObject $restResult
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' -Params 'Uri', 'Method'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraIssueWatcher

            defParam $command 'Issue'
            defParam $command 'Credential'
        }

        Context "Behavior testing" {

            It "Obtains all Jira watchers from a Jira issue if the issue key is provided" {
                $watchers = Get-JiraIssueWatcher -Issue $issueKey
                $watchers | Should Not BeNullOrEmpty
                @($watchers).Count | Should Be 1
                $watchers.Name | Should Be "fred"
                $watchers.DisplayName | Should Be "Fred F. User"
                $watchers.RestUrl | Should Be "$jiraServer/jira/rest/api/2/user?username=fred"

                # Get-JiraIssue should be called to identify the -Issue parameter
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It

                # Normally, this would be called once in Get-JiraIssue and a second time in Get-JiraIssueWatcher, but
                # since we've mocked Get-JiraIssue out, it will only be called once.
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Obtains all Jira watchers from a Jira issue if the Jira object is provided" {
                $issue = Get-JiraIssue -Key $issueKey
                $watchers = Get-JiraIssueWatcher -Issue $issue
                $watchers | Should Not BeNullOrEmpty
                $watchers.name | Should Be "fred"
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Handles pipeline input from Get-JiraIssue" {
                $watchers = Get-JiraIssue -Key $issueKey | Get-JiraIssueWatcher
                $watchers | Should Not BeNullOrEmpty
                $watchers.name | Should Be "fred"
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
        }
    }
}
