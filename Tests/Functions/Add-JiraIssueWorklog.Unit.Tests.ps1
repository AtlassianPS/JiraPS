Describe "Add-JiraIssueWorklog" -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH* -ErrorAction SilentlyContinue
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

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1" -ErrorAction Stop

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest -ErrorAction Stop

        # helpers used by tests (defParam / ShowMockInfo)
        . "$PSScriptRoot/../Shared.ps1"

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
    "self": "$jiraServer/rest/api/2/issue/$issueID/worklog/$worklogitemID",
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

        # Helper function for creating issue objects
        function New-TestJiraIssue {
            param($Key = $issueKey)
            $object = [PSCustomObject] @{
                ID      = $issueID
                Key     = $Key
                RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            New-TestJiraIssue -Key $Key
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/worklog"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
            ConvertFrom-Json $restResponse
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
    }

    #############
    # Tests
    #############

    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name Add-JiraIssueWorklog

            defParam $command 'Comment'
            defParam $command 'Issue'
            defParam $command 'TimeSpent'
            defParam $command 'DateStarted'
            defParam $command 'VisibleRole'
            defParam $command 'Credential'
        }
    }

    Context "Behavior testing" {
        It "Adds a worklog item to an issue in JIRA" {
            $commentResult = Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent 3600 -DateStarted "2018-01-01"
            $commentResult | Should -Not -BeNullOrEmpty
        }

        It "Accepts pipeline input from Get-JiraIssue" {
            # Mock for when Get-JiraIssue is called directly in tests (outside module scope)
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'GET' -and $URI -like "$jiraServer/rest/api/2/issue/$issueKey*"} {
                ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                @{
                    id = $issueID
                    key = $issueKey
                    self = "$jiraServer/rest/api/2/issue/$issueID"
                    fields = @{}
                }
            }

            $commentResult = Get-JiraIssue -Key $IssueKey | Add-JiraIssueWorklog -Comment 'This is a test worklog item from Pester, using the pipeline!' -TimeSpent "3600" -DateStarted "2018-01-01"
            $commentResult | Should -Not -BeNullOrEmpty
        }

        It "formats DateStarted independently of the input" {
            Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted "2018-01-01"
            Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted (Get-Date)
            Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted (Get-Date -Date "01.01.2000")

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Body -match '\"started\":\s*"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}[\+\-]\d{4}"'
            } -Exactly -Times 3
        }
    }

    Context "Internal Call Validation" {
        It "Uses Invoke-JiraMethod to add the worklog" {
            Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent 3600 -DateStarted "2018-01-01"

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
        }

        It "Calls Resolve-JiraIssueObject to set the issue object" {
            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                New-TestJiraIssue -Key $issueKey
            }
            Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent 3600 -DateStarted "2018-01-01"

            Should -Invoke -CommandName Resolve-JiraIssueObject -ModuleName JiraPS -Exactly -Times 1
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH* -ErrorAction SilentlyContinue
    }
}
