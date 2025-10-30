#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Get-JiraIssueComment" -Tag 'Unit' {

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

        # helpers used by tests (defParam / ShowMockInfo)
        . "$PSScriptRoot/../Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'
        $issueID = 41701
        $issueKey = 'IT-3676'

        $restResult = @"
{
    "startAt": 0,
    "maxResults": 1,
    "total": 1,
    "comments": [
        {
            "self": "$jiraServer/rest/api/2/issue/$issueID/comment/90730",
            "id": "90730",
            "body": "Test comment",
            "created": "2015-05-01T16:24:38.000-0500",
            "updated": "2015-05-01T16:24:38.000-0500",
            "visibility": {
                "type": "role",
                "value": "Developers"
            }
        }
    ]
}
"@

        #region Mocks
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        # Helper function for creating issue objects
        function Get-TestJiraIssue {
            param([string]$Key = $issueKey)
            $object = [PSCustomObject] @{
                ID      = $issueID
                Key     = $Key
                RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            $object
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            Get-TestJiraIssue -Key $issueKey
        }

        # Mock Resolve-JiraIssueObject -ModuleName JiraPS {
        #     Get-JiraIssue -Key $Issue
        # }

        # Obtaining comments from an issue...this is IT-3676 in the test environment
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/comment"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            (ConvertFrom-Json -InputObject $restResult).comments
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    #############
    # Tests
    #############

    It "Obtains all Jira comments from a Jira issue if the issue key is provided" {
        $comments = Get-JiraIssueComment -Issue $issueKey

        $comments | Should -Not -BeNullOrEmpty
        @($comments).Count | Should -Be 1
        $comments.ID | Should -Be 90730
        $comments.Body | Should -Be 'Test comment'

        # Get-JiraIssue should be called to identify the -Issue parameter
        Should -Invoke -CommandName Get-JiraIssue -ModuleName JiraPS -Times 1 -Exactly

        # Normally, this would be called once in Get-JiraIssue and a second time in Get-JiraIssueComment, but
        # since we've mocked Get-JiraIssue out, it will only be called once.
        Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Exactly
    }

    It "Obtains all Jira comments from a Jira issue if the Jira object is provided" {
        $issue = Get-TestJiraIssue -Key $issueKey
        $comments = Get-JiraIssueComment -Issue $issue

        $comments | Should -Not -BeNullOrEmpty
        $comments.ID | Should -Be 90730

        Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Exactly
    }

    It "Handles pipeline input from Get-JiraIssue" {
        $comments = Get-TestJiraIssue -Key $issueKey | Get-JiraIssueComment

        $comments | Should -Not -BeNullOrEmpty
        $comments.ID | Should -Be 90730

        Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Exactly
    }
}
