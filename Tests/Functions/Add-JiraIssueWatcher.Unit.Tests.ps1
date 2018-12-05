#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Add-JiraIssueWatcher" -Tag 'Unit' {

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

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            $object = [PSCustomObject] @{
                ID      = $issueID
                Key     = $issueKey
                RestUrl = "$jiraServer/rest/api/latest/issue/$issueID"
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        Mock Resolve-JiraIssueObject -ModuleName JiraPS {
            Get-JiraIssue -Key $Issue
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/latest/issue/$issueID/watchers"} {
            ShowMockInfo 'Invoke-JiraMethod' -Params 'Uri', 'Method'
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
            $command = Get-Command -Name Add-JiraIssueWatcher

            defParam $command 'Watcher'
            defParam $command 'Issue'
            defParam $command 'Credential'
        }

        Context "Behavior testing" {

            It "Adds a Watcher to an issue in JIRA" {
                $WatcherResult = Add-JiraIssueWatcher -Watcher 'fred' -Issue $issueKey
                $WatcherResult | Should BeNullOrEmpty

                # Get-JiraIssue should be used to identify the issue parameter
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It

                # Invoke-JiraMethod should be used to add the Watcher
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Accepts pipeline input from Get-JiraIssue" {
                $WatcherResult = Get-JiraIssue -Key $issueKey | Add-JiraIssueWatcher -Watcher 'fred'
                $WatcherResult | Should BeNullOrEmpty

                # Get-JiraIssue should be called once here, and once inside Add-JiraIssueWatcher (to identify the InputObject parameter)
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
        }
    }
}
