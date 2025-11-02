#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Remove-JiraIssueWatcher" -Tag 'Unit' {

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

        . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defParam / ShowMockInfo)

        $jiraServer = 'http://jiraserver.example.com'
        $issueID = 41701
        $issueKey = 'IT-3676'

        #helper function to generate test JiraIssue object
        function Get-TestJiraIssue {
            $object = [PSCustomObject] @{
                ID      = $issueID
                Key     = $issueKey
                RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            Get-TestJiraIssue
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'DELETE' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/watchers?username=fred"} {
            ShowMockInfo 'Invoke-JiraMethod' -Params 'Uri', 'Method'
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' -Params 'Uri', 'Method'
            throw "Unidentified call to Invoke-JiraMethod"
        }
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    #############
    # Tests
    #############

    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name Remove-JiraIssueWatcher

            defParam $command 'Watcher'
            defParam $command 'Issue'
            defParam $command 'Credential'
        }
    }

    Context "Behavior testing" {

        It "Removes a Watcher from an issue in JIRA" {
            $WatcherResult = Remove-JiraIssueWatcher -Watcher 'fred' -Issue $issueKey
            $WatcherResult | Should -BeNullOrEmpty

            # Get-JiraIssue should be used to identiyf the issue parameter
            Should -Invoke 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 1

            # Invoke-JiraMethod should be used to add the Watcher
            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
        }

        It "Accepts pipeline input from Get-JiraIssue" {
            $WatcherResult = Get-TestJiraIssue | Remove-JiraIssueWatcher -Watcher 'fred'
            $WatcherResult | Should -BeNullOrEmpty

            # Get-JiraIssue should be called once here, and once inside Add-JiraIssueWatcher (to identify the InputObject parameter)
            # WARN: Right now, our mock of JiraIssue objects have a RestURL property, which causes
            # Resolve-JiraIssueObject to simply return $InputObject (no call to Get-JiraIssue). This may need to be double-checked.
            Should -Invoke 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 0
            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
        }
    }
}
