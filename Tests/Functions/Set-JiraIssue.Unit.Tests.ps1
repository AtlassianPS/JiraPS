#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Set-JiraIssue" -Tag 'Unit' {

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

        $jiraServer = "https://jira.example.com"

        Mock Get-JiraConfigServer {
            $jiraServer
        }
        Mock Get-JiraUser {
            [PSCustomObject] @{
                'Name' = 'username'
            }
        }

        Mock Set-JiraIssueLabel {}

        Mock Get-JiraIssue {
            $object = [PSCustomObject] @{
                'RestURL' = "$jiraServer/rest/api/2/issue/12345"
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        Mock Resolve-JiraIssueObject -ModuleName JiraPS {
            Get-JiraIssue -Key $Issue
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq "Put" -and $Uri -like "$jiraServer/rest/api/*/issue/12345"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
        }
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq "Put" -and $Uri -like "$jiraServer/rest/api/*/issue/12345/assignee"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
        }

        # If we don't override this in a context or test, we don't want it to
        # actually try to query a JIRA instance
        Mock Invoke-JiraMethod {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Context "Sanity checking" {
            $command = Get-Command -Name Set-JiraIssue

            defParam $command 'Issue'
            defParam $command 'Summary'
            defParam $command 'Description'
            defParam $command 'Assignee'
            defParam $command 'Label'
            defParam $command 'AddComment'
            defParam $command 'Fields'
            defParam $command 'Credential'
            defParam $command 'PassThru'

            It "Supports the Key alias for the Issue parameter" {
                $command.Parameters.Item('Issue').Aliases | Where-Object -FilterScript {$_ -eq 'Key'} | Should Not BeNullOrEmpty
            }
        }

        Context "Behavior testing" {

            It "Modifies the summary of an issue if the -Summary parameter is passed" {
                { Set-JiraIssue -Issue TEST-001 -Summary 'New summary' } | Should Not Throw
                # The String in the ParameterFilter is made from the keywords
                # we should expect to see in the JSON that should be sent,
                # including the summary provided in the test call above.
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/2/issue/12345" -and $Body -like '*summary*set*New summary*' }
            }

            It "Modifies the description of an issue if the -Description parameter is passed" {
                { Set-JiraIssue -Issue TEST-001 -Description 'New description' } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/2/issue/12345" -and $Body -like '*description*set*New description*' }
            }

            It "Modifies the description of an issue without sending notifications if the -Description parameter is passed" {
                { Set-JiraIssue -Issue TEST-001 -Description 'New description' -SkipNotification } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/2/issue/12345" -and $Body -like '*description*set*New description*' }
            }

            It "Modifies the assignee of an issue if -Assignee is passed" {
                { Set-JiraIssue -Issue TEST-001 -Assignee username } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/2/issue/12345/assignee" -and $Body -like '*name*username*' }
            }

            It "Unassigns an issue if 'Unassigned' is passed to the -Assignee parameter" {
                { Set-JiraIssue -Issue TEST-001 -Assignee unassigned } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/2/issue/12345/assignee" -and $Body -like '*"name":*null*' }
            }

            It "Sets the default assignee to an issue if 'Default' is passed to the -Assignee parameter" {
                { Set-JiraIssue -Issue TEST-001 -Assignee default } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/2/issue/12345/assignee" -and $Body -like '*"name":*"-1"*' }
            }

            It "Calls Invoke-JiraMethod twice if using Assignee and another field" {
                { Set-JiraIssue -Issue TEST-001 -Summary 'New summary' -Assignee username } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/2/issue/12345" -and $Body -like '*summary*set*New summary*' }
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/2/issue/12345/assignee" -and $Body -like '*name*username*' }
            }

            It "Uses Set-JiraIssueLabel with the -Set parameter when the -Label parameter is used" {
                { Set-JiraIssue -Issue TEST-001 -Label 'test' } | Should Not Throw
                Assert-MockCalled -CommandName Set-JiraIssueLabel -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Set -ne $null }
            }

            It "Adds a comment if the -AddComemnt parameter is passed" {
                { Set-JiraIssue -Issue TEST-001 -AddComment 'New Comment' } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $Uri -like "$jiraServer/rest/api/2/issue/12345" -and $Body -like '*comment*add*body*New Comment*' }
            }

            It "Updates custom fields if provided to the -Fields parameter" {
                Mock Get-JiraField {
                    [PSCustomObject] @{
                        'Name' = $Field
                        'ID'   = $Field
                    }
                }
                { Set-JiraIssue -Issue TEST-001 -Fields @{'customfield_12345' = 'foo'; 'customfield_67890' = 'bar'; 'customfield_111222' = @(@{'value' = 'foobar'})} } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/*/issue/12345" -and $Body -like '*customfield_12345*set*foo*' }
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/*/issue/12345" -and $Body -like '*customfield_67890*set*bar*' }
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/*/issue/12345" -and $Body -like '*customfield_111222*set*foobar*' }
            }

        }

        Context "Input testing" {
            It "Accepts an issue key for the -Issue parameter" {
                { Set-JiraIssue -Issue TEST-001 -Summary 'Test summary - using issue key' } | Should Not Throw
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Accepts an issue object for the -Issue parameter" {
                $issue = Get-JiraIssue -Key TEST-001
                { Set-JiraIssue -Issue $issue -Summary 'Test summary - Object' } | Should Not Throw
                # Get-JiraIssue is called once explicitly in this test, and a
                # second time by Set-JiraIssue
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Accepts the output of Get-JiraObject by pipeline for the -Issue paramete" {
                { Get-JiraIssue -Key TEST-001 | Set-JiraIssue -Summary 'Test summary - InputObject pipeline' } | Should Not Throw
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Throws an exception if an invalid issue is provided" {
                Mock Get-JiraIssue {}
                # We're cheating a bit here and forcing Write-Error to be a
                # terminating error.
                { Set-JiraIssue -Key FAKE -Summary 'Test' -ErrorAction Stop } | Should Throw
            }

            It "Throws an exception if an invalid user is specified for the -Assignee parameter" {
                { Set-JiraIssue -Key TEST-001 -Assignee notReal } | Should Throw
            }
        }
    }
}
