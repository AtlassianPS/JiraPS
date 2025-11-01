#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Invoke-JiraIssueTransition" -Tag 'Unit' {

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

        . "$PSScriptRoot/../Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'
        $issueID = 41701
        $issueKey = 'IT-3676'

        #Helper functions to generate test Jira objects
        function Get-TestJiraIssue {
            $t1 = [PSCustomObject] @{
                Name = 'Start Progress'
                ID   = 11
            }
            $t1.PSObject.TypeNames.Insert(0, 'JiraPS.Transition')
            $t2 = [PSCustomObject] @{
                Name = 'Resolve'
                ID   = 81
            }
            $t2.PSObject.TypeNames.Insert(0, 'JiraPS.Transition')

            $object = [PSCustomObject] @{
                ID         = $issueID
                Key        = $issueKey
                RestUrl    = "$jiraServer/rest/api/2/issue/$issueID"
                Transition = @($t1, $t2)
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraField -ModuleName JiraPS {
            $object = [PSCustomObject] @{
                'Name' = $Field
                'ID'   = $Field
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
            return $object
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            Get-TestJiraIssue
        }

        <# Mock Resolve-JiraIssueObject -ModuleName JiraPS {
            Get-JiraIssue -Key $Issue
        } #>

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Post' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/transitions"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            # This should return a 204 status code, so no data should actually be returned
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

    It "Performs a transition on a Jira issue when given an issue key and transition ID" {
        { $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 } | Should -Not -Throw

        Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1
        Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
    }

    #NOTE: There were original assertions in the next two tests that Get-JiraIssue was called within function.
    # This is only true if -PassThru is used.
    It "Performs a transition on a Jira issue when given an issue object and transition object" {
        $issue = Get-TestJiraIssue -Key $issueKey
        $transition = $issue.Transition[0]
        { Invoke-JiraIssueTransition -Issue $issue -Transition $transition } | Should -Not -Throw

        Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
    }

    It "Handles pipeline input from Get-JiraIssue" {
        { Get-TestJiraIssue | Invoke-JiraIssueTransition -Transition 11 } | Should -Not -Throw

        Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
    }


    It "Updates custom fields if provided to the -Fields parameter" {
        {
            $parameter = @{
                Issue      = $issueKey
                Transition = 11
                Fields     = @{
                    'customfield_12345' = 'foo'
                    'customfield_67890' = 'bar'
                }
            }
            Invoke-JiraIssueTransition @parameter
        } | Should -Not -Throw

        Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Post' -and $URI -like "*/rest/api/2/issue/$issueID/transitions" -and $Body -like '*customfield_12345*set*foo*' }
        Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Post' -and $URI -like "*/rest/api/2/issue/$issueID/transitions" -and $Body -like '*customfield_67890*set*bar*' }
    }

    It "Updates assignee name if provided to the -Assignee parameter" {
        Mock Get-JiraUser -ModuleName JiraPS {
            [PSCustomObject] @{
                'Name'    = 'powershell-user'
                'RestUrl' = "$jiraServer/rest/api/2/user?username=powershell-user"
            }
        }
        { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Assignee 'powershell-user'} | Should -Not -Throw

        Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Post' -and $URI -like "*/rest/api/2/issue/$issueID/transitions" -and $Body -like '*name*powershell-user*' }
    }

    It "Unassigns an issue if 'Unassigned' is passed to the -Assignee parameter" {
        { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Assignee 'Unassigned'} | Should -Not -Throw

        Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Post' -and $URI -like "*/rest/api/2/issue/$issueID/transitions" -and $Body -like '*name*""*' }
    }

    It "Adds a comment if provide to the -Comment parameter" {
        { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Comment 'test comment'} | Should -Not -Throw

        Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Post' -and $URI -like "*/rest/api/2/issue/$issueID/transitions" -and $Body -like '*body*test comment*' }
    }

    It "Returns the Issue object when -Passthru is provided" {
        { $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Passthru} | Should -Not -Throw
        $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Passthru
        $result | Should -Not -BeNullOrEmpty

        Should -Invoke -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 4
    }

    It "Does not return a value when -Passthru is omitted" {
        { $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11} | Should -Not -Throw
        $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11
        $result | Should -BeNullOrEmpty

        Should -Invoke -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }
}
