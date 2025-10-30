#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Remove-JiraRemoteLink" -Tag 'Unit' {

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

        $testIssueKey = 'EX-1'

        $testLink = @"
{
    "id": 10000,
    "self": "http://www.example.com/jira/rest/api/issue/MKY-1/remotelink/10000",
    "globalId": "system=http://www.mycompany.com/support&id=1",
    "application": {
        "type": "com.acme.tracker",
        "name": "My Acme Tracker"
    },
    "relationship": "causes",
    "object": {
        "url": "http://www.mycompany.com/support?id=1",
        "title": "TSTSUP-111",
        "summary": "Crazy customer support issue",
        "icon": {
            "url16x16": "http://www.mycompany.com/support/ticket.png",
            "title": "Support Ticket"
        }
    }
}
"@

        #helper function to generate test JiraIssue object
        function Get-TestJiraIssue {
            $object = [PSCustomObject] @{
                'RestURL' = 'https://jira.example.com/rest/api/2/issue/12345'
                'Key'     = $testIssueKey
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        #helper function to generate test JiraIssue object
        function Get-TestJiraRemoteLink {
            $object = ConvertFrom-Json $testLink
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLinkType')
            return $object
        }

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue {
            Get-TestJiraIssue
        }

        Mock Resolve-JiraIssueObject -ModuleName JiraPS {
            Get-TestJiraIssue
        }

        Mock Get-JiraRemoteLink {
            Get-TestJiraRemoteLink
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'DELETE'} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            # This REST method should produce no output
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
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

    It "Accepts a issue key to the -Issue parameter" {
        { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force } | Should -Not -Throw
        Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
    }

    It "Accepts a JiraPS.Issue object to the -Issue parameter" {
        $Issue = Get-TestJiraIssue
        { Remove-JiraRemoteLink -Issue $Issue -LinkId 10000 -Force } | Should -Not -Throw
        Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
    }

    It "Accepts pipeline input from Get-JiraIssue" {
        { Get-TestJiraIssue | Remove-JiraRemoteLink -LinkId 10000 -Force } | Should -Not -Throw
        Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
    }

    It "Accepts the output of Get-JiraRemoteLink" {
        $remoteLink = Get-TestJiraRemoteLink
        { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId $remoteLink.id -Force } | Should -Not -Throw
        Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
    }

    It "Removes a group from JIRA" {
        { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force } | Should -Not -Throw
        Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
    }

    It "Provides no output" {
        Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force | Should -BeNullOrEmpty
    }
}
