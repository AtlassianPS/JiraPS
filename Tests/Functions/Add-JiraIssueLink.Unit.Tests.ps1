#requires -modules BuildHelpers
#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7.1' }

Describe 'Add-JiraIssueLink' -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH* -ErrorAction SilentlyContinue

        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        if ($projectRoot -like '*Release') {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }

        Import-Module BuildHelpers
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

        $env:BHManifestToTest = $env:BHPSModuleManifest
        $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($script:isBuild) {
            $pattern = [regex]::Escape($env:BHProjectPath)
            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1" -ErrorAction Stop

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest -ErrorAction Stop

        # helpers used by tests (defParam / ShowMockInfo)
        . "$PSScriptRoot/../Shared.ps1"

    }

    #############
    # Tests
    #############

    Context 'Sanity checking' {
        It "Has expected parameters" {
            $command = Get-Command -Name Add-JiraIssueLink
            defParam $command 'Issue'
            defParam $command 'IssueLink'
            defParam $command 'Comment'
            defParam $command 'Credential'
        }
    }

    Context 'Functionality' {
        BeforeAll {
            # common test data
            $jiraServer = 'http://jiraserver.example.com'
            $issueKey   = 'TEST-01'
            $issueLink  = [pscustomobject]@{
                outwardIssue = [pscustomobject]@{ key = 'TEST-10' }
                type         = [pscustomobject]@{ name = 'Composition' }
            }

            Mock Get-JiraConfigServer -ModuleName JiraPS { $jiraServer }

            Mock Get-JiraIssue {
                $obj = [pscustomobject]@{ Key = $issueKey }
                $obj.PSObject.TypeNames.Insert(0,'JiraPS.Issue')
                $obj
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Get-JiraIssue -Key $issueKey
            }

            # catch-all: fail on unexpected Invoke-JiraMethod usage
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                ShowMockInfo 'Invoke-JiraMethod' 'Method','Uri'
                throw 'Unidentified call to Invoke-JiraMethod'
            }

            # specific POST for issueLink
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'POST' -and $Uri -eq "$jiraServer/rest/api/2/issueLink"
            } { $true }
        }

        It 'Adds a new IssueLink' {
            { Add-JiraIssueLink -Issue $issueKey -IssueLink $issueLink } | Should -Not -Throw
            Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName JiraPS -Times 1 -Exactly
        }

        It 'Validates the IssueType provided' {
            $bad = [pscustomobject]@{ type = 'foo' }
            { Add-JiraIssueLink -Issue $issueKey -IssueLink $bad } | Should -Throw "Invalid Parameter"
        }

        #BUG: Bad test originally. Command call was throwing, but because it was hitting the catch-all mock,
        # not because of actual pipeline validation (confirm by specifying a certain throw message)
        <# It 'Validates pipeline input object' {
            { 'foo' | Add-JiraIssueLink -IssueLink $issueLink } | Should -Throw "*parameter 'Issue'*"
        } #>
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH* -ErrorAction SilentlyContinue
    }
}
