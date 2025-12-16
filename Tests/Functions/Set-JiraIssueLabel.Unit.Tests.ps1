#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Set-JiraIssueLabel" -Tag 'Unit' {

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

        $jiraServer = 'https://jira.example.com'

        #helper functions to generate test Jira objects
        function Get-TestJiraIssue {
            $object = [PSCustomObject] @{
                'Id'      = 123
                'RestURL' = "$jiraServer/rest/api/2/issue/12345"
                'Labels'  = @('existingLabel1', 'existingLabel2')
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            $jiraServer
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            Get-TestJiraIssue
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq "Put" -and $Uri -like "$jiraServer/rest/api/*/issue/12345"} {
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

    }
    Context "Sanity checking" {
        BeforeAll {
            $command = Get-Command -Name Set-JiraIssueLabel
        }

        It "Has the expected parameters" {
            defParam $command 'Issue'
            defParam $command 'Set'
            defParam $command 'Add'
            defParam $command 'Remove'
            defParam $command 'Clear'
            defParam $command 'Credential'
            defParam $command 'PassThru'
        }

        It "Has the expected aliases" {
            defAlias $command 'Key' 'Issue'
            defAlias $command 'Label' 'Set'
            defAlias $command 'Replace' 'Set'
        }
    }

    Context "Behavior testing" {
        It "Replaces all issue labels if the Set parameter is supplied" {
            { Set-JiraIssueLabel -Issue TEST-001 -Set 'testLabel1', 'testLabel2' } | Should -Not -Throw
            # The String in the ParameterFilter is made from the keywords
            # we should expect to see in the JSON that should be sent,
            # including the summary provided in the test call above.
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345' -and $Body -like '*update*labels*set*testLabel1*testLabel2*' }
        }

        It "Adds new labels if the Add parameter is supplied" {
            { Set-JiraIssueLabel -Issue TEST-001 -Add 'testLabel3' } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345' -and $Body -like '*update*labels*set*testLabel3*' }
        }

        It "Removes labels if the Remove parameter is supplied" {
            # The issue already has labels existingLabel1 and
            # existingLabel2. It should be set to just existingLabel2.
            { Set-JiraIssueLabel -Issue TEST-001 -Remove 'existingLabel1' } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345' -and $Body -like '*update*labels*set*existingLabel2*' }
        }

        It "Clears all labels if the Clear parameter is supplied" {
            { Set-JiraIssueLabel -Issue TEST-001 -Clear } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345' -and $Body -like '*update*labels*set*' }
        }

        It "Allows use of both Add and Remove parameters at the same time" {
            { Set-JiraIssueLabel -Issue TEST-001 -Add 'testLabel1' -Remove 'testLabel2' } | Should -Not -Throw
        }
    }

    Context "Input testing" {
        It "Accepts an issue key for the -Issue parameter" {
            { Set-JiraIssueLabel -Issue TEST-001 -Set 'testLabel1' } | Should -Not -Throw
            Should -Invoke -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
        }

        #NOTE: There were original assertions in the next two tests that Get-JiraIssue was called within function.
        # This is only true if -PassThru is used.
        It "Accepts an issue object for the -Issue parameter" {
            $issue = Get-TestJiraIssue
            { Set-JiraIssueLabel -Issue $issue -Set 'testLabel1' } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
        }

        It "Accepts the output of Get-JiraIssue by pipeline for the -Issue parameter" {
            { Get-TestJiraIssue | Set-JiraIssueLabel -Set 'testLabel1' } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }
}
