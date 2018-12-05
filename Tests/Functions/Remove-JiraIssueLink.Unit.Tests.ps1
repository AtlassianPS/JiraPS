#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Remove-JiraIssueLink" -Tag 'Unit' {

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

        $issueLinkId = 1234

        # We don't care about anything except for the id
        $resultsJson = @"
{
    "id": "$issueLinkId",
    "self": "",
    "type": {},
    "inwardIssue": {},
    "outwardIssue": {}
}
"@

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssueLink -ModuleName JiraPS {
            $obj = [PSCustomObject]@{
                "id"          = $issueLinkId
                "type"        = "foo"
                "inwardIssue" = "bar"
            }
            $obj.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLink')
            return $obj
        }

        Mock Get-JiraIssue -ModuleName JiraPS -ParameterFilter {$Key -eq "TEST-01"} {
            # We don't care about the content of any field except for the id of the issuelinks
            $issue = [PSCustomObject]@{
                issueLinks = @( (Get-JiraIssueLink -Id 1234) )
            }
            $issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $issue
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/*/issueLink/1234"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        Context "Sanity checking" {
            $command = Get-Command -Name Remove-JiraIssueLink

            defParam $command 'IssueLink'
            defParam $command 'Credential'
        }

        Context "Functionality" {

            It "Accepts generic object with the correct properties" {
                $issueLink = Get-JiraIssueLink -Id 1234
                $issue = Get-JiraIssue -Key TEST-01
                { Remove-JiraIssueLink -IssueLink $issueLink } | Should Not Throw
                { Remove-JiraIssueLink -IssueLink $issue } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 2 -Scope It
            }

            It "Accepts a JiraPS.Issue object over the pipeline" {
                { Get-JiraIssue -Key TEST-01 | Remove-JiraIssueLink } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
            }

            It "Accepts a JiraPS.IssueType over the pipeline" {
                { Get-JiraIssueLink -Id 1234 | Remove-JiraIssueLink } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
            }

            It "Validates pipeline input" {
                { @{id = 1} | Remove-JiraIssueLink -ErrorAction SilentlyContinue } | Should Throw
            }
        }
    }
}
