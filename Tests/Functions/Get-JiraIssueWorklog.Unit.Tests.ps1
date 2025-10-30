#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Get-JiraIssueWorklog" -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        if ($projectRoot -like "*Release") {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }

        Import-Module BuildHelpers
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

        $env:BHManifestToTest = $env:BHPSModuleManifest
        $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($script:isBuild) {
            $Pattern = [regex]::Escape($env:BHProjectPath)

            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest

        . "$PSScriptRoot/../Shared.ps1"


        $jiraServer = 'http://jiraserver.example.com'
        $issueID = 41701
        $issueKey = 'IT-3676'

        # Helper function to create test JiraIssue object
        function Get-TestJiraIssue {
            param($Key, $ID)
            $object = [PSCustomObject] @{
                ID      = $ID
                Key     = $Key
                RestUrl = "$jiraServer/rest/api/2/issue/$ID"
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        $restResult = @"
{
    "startAt": 0,
    "maxResults": 1,
    "total": 1,
    "worklogs": [
        {
            "self": "$jiraServer/rest/api/2/issue/$issueID/worklog/90730",
            "id": "90730",
            "comment": "Test comment",
            "created": "2015-05-01T16:24:38.000-0500",
            "updated": "2015-05-01T16:24:38.000-0500",
            "visibility": {
                "type": "role",
                "value": "Developers"
            },
            "timeSpent": "3m",
            "timeSpentSeconds": 180
        }
    ]
}
"@

        #region Mocks
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            Get-TestJiraIssue -Key $Key -ID $issueID
        }

        # Obtaining worklog from an issue...this is IT-3676 in the test environment
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/worklog"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            (ConvertFrom-Json -InputObject $restResult).worklogs
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks
    }

    #############
    # Tests
    #############

    Context "Behavior checking" {
        It "Obtains all Jira worklogs from a Jira issue if the issue key is provided" {
            $worklogs = Get-JiraIssueWorklog -Issue $issueKey

            $worklogs | Should -Not -BeNullOrEmpty
            @($worklogs).Count | Should -Be 1
            $worklogs.ID | Should -Be 90730
            $worklogs.Comment | Should -Be 'Test comment'
            $worklogs.TimeSpent | Should -Be '3m'
            $worklogs.TimeSpentSeconds | Should -Be 180
        }

        It "Obtains all Jira worklogs from a Jira issue if the Jira object is provided" {
            Mock Get-JiraIssue {
                Get-TestJiraIssue -Key $Key -ID $issueID
            }
            $issue = Get-JiraIssue -Key $issueKey
            $worklogs = Get-JiraIssueWorklog -Issue $issue

            $worklogs | Should -Not -BeNullOrEmpty
            $worklogs.ID | Should -Be 90730
        }

        It "Handles pipeline input from Get-JiraIssue" {
            Mock Get-JiraIssue {
                Get-TestJiraIssue -Key $Key -ID $issueID
            }
            $worklogs = Get-JiraIssue -Key $issueKey | Get-JiraIssueWorklog

            $worklogs | Should -Not -BeNullOrEmpty
            $worklogs.ID | Should -Be 90730
        }
    }

    Context "Internal call validation" {
        It "Calls Invoke-JiraMethod to obtain the worklog" {
            Get-JiraIssueWorklog -Issue $issueKey | Out-Null

            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly 1
        }

        It "Calls Get-JiraIssue when an issue key is provided" {
            Get-JiraIssueWorklog -Issue $issueKey | Out-Null

            Should -Invoke 'Get-JiraIssue' -ModuleName JiraPS -Exactly 1
        }

        It "Does not call Get-JiraIssue if a JiraPS.Issue object is provided" {
            $issue = Get-TestJiraIssue $issueKey $issueID
            Get-JiraIssueWorklog -Issue $issue | Out-Null

            Should -Invoke 'Get-JiraIssue' -ModuleName JiraPS -Exactly 0
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }
}
