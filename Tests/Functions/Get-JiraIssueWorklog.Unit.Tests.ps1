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
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"


        $jiraServer = 'http://jiraserver.example.com'
        $issueID = 41701
        $issueKey = 'IT-3676'

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
            $object = [PSCustomObject] @{
                ID      = $issueID
                Key     = $issueKey
                RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        Mock Resolve-JiraIssueObject -ModuleName JiraPS {
            Get-JiraIssue -Key $Issue
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

        #############
        # Tests
        #############

        It "Obtains all Jira worklogs from a Jira issue if the issue key is provided" {
            $worklogs = Get-JiraIssueWorklog -Issue $issueKey

            $worklogs | Should -Not -BeNullOrEmpty
            @($worklogs).Count | Should -Be 1
            $worklogs.ID | Should -Be 90730
            $worklogs.Comment | Should -Be 'Test comment'
            $worklogs.TimeSpent | Should -Be '3m'
            $worklogs.TimeSpentSeconds | Should -Be 180

            # Get-JiraIssue should be called to identify the -Issue parameter
            Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It

            # Normally, this would be called once in Get-JiraIssue and a second time in Get-JiraIssueComment, but
            # since we've mocked Get-JiraIssue out, it will only be called once.
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        It "Obtains all Jira worklogs from a Jira issue if the Jira object is provided" {
            $issue = Get-JiraIssue -Key $issueKey
            $worklogs = Get-JiraIssueWorklog -Issue $issue

            $worklogs | Should -Not -BeNullOrEmpty
            $worklogs.ID | Should -Be 90730

            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        It "Handles pipeline input from Get-JiraIssue" {
            $worklogs = Get-JiraIssue -Key $issueKey | Get-JiraIssueWorklog

            $worklogs | Should -Not -BeNullOrEmpty
            $worklogs.ID | Should -Be 90730

            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }
    }
}
