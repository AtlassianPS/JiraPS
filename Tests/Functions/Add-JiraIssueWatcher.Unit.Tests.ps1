#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Add-JiraIssueWatcher" -Tag 'Unit' {

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
        $issueID = 41701
        $issueKey = 'IT-3676'

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

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/watchers"} {
            ShowMockInfo 'Invoke-JiraMethod' -Params 'Uri', 'Method'
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' -Params 'Uri', 'Method'
            throw "Unidentified call to Invoke-JiraMethod"
        }
    }

    #############
    # Tests
    #############

    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name Add-JiraIssueWatcher

            defParam $command 'Watcher'
            defParam $command 'Issue'
            defParam $command 'Credential'
        }
    }

    Context "Behavior testing" {

        It "Adds a Watcher to an issue in JIRA" {
            $WatcherResult = Add-JiraIssueWatcher -Watcher 'fred' -Issue $issueKey
            $WatcherResult | Should -BeNullOrEmpty
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

            $WatcherResult = Get-JiraIssue -Key $issueKey | Add-JiraIssueWatcher -Watcher 'fred'
            $WatcherResult | Should -BeNullOrEmpty
        }
    }

    Context "Internal Call Validation" {
        BeforeAll {
            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                New-TestJiraIssue -Key $issueKey
            }
        }

        It "Uses Invoke-JiraMethod to add the Watcher" {
            Add-JiraIssueWatcher -Watcher 'fred' -Issue $issueKey | Out-Null

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
        }

        It "Calls Resolve-JiraIssueObject to set the issue object" {
            Add-JiraIssueWatcher -Watcher 'fred' -Issue $issueKey | Out-Null

            Should -Invoke -CommandName Resolve-JiraIssueObject -ModuleName JiraPS -Exactly -Times 1
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH* -ErrorAction SilentlyContinue
    }
}
