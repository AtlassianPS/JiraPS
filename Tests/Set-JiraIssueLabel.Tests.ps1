﻿. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "Set-JiraIssueLabel" {
        if ($ShowDebugText) {
            Mock "Write-Debug" {
                Write-Host "       [DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraConfigServer {
            'https://jira.example.com'
        }

        Mock Get-JiraIssue {
            [PSCustomObject] @{
                'RestURL' = 'https://jira.example.com/rest/api/2/issue/12345';
                'Labels'  = @('existingLabel1', 'existingLabel2')
            }
        }

        # If we don't override this in a context or test, we don't want it to
        # actually try to query a JIRA instance
        Mock Invoke-JiraMethod {}

        Context "Sanity checking" {
            $command = Get-Command -Name Set-JiraIssueLabel

            function defParam($name) {
                It "Has a -$name parameter" {
                    $command.Parameters.Item($name) | Should Not BeNullOrEmpty
                }
            }

            function defAlias($name, $definition) {
                It "Supports the $name alias for the $definition parameter" {
                    $command.Parameters.Item($definition).Aliases | Where-Object -FilterScript {$_ -eq $name} | Should Not BeNullOrEmpty
                }
            }

            defParam 'Issue'
            defParam 'Set'
            defParam 'Add'
            defParam 'Remove'
            defParam 'Clear'
            defParam 'Credential'
            defParam 'PassThru'

            defAlias 'Key' 'Issue'
            defAlias 'Label' 'Set'
            defAlias 'Replace' 'Set'
        }

        Context "Behavior testing" {
            Mock Invoke-JiraMethod {
                if ($ShowMockData) {
                    Write-Host "       Mocked Invoke-JiraMethod" -ForegroundColor Cyan
                    Write-Host "         [Uri]     $Uri" -ForegroundColor Cyan
                    Write-Host "         [Method]  $Method" -ForegroundColor Cyan
                    Write-Host "         [Body]    $Body" -ForegroundColor Cyan
                }
            }

            It "Replaces all issue labels if the Set parameter is supplied" {
                { Set-JiraIssueLabel -Issue TEST-001 -Set 'testLabel1', 'testLabel2' } | Should Not Throw
                # The String in the ParameterFilter is made from the keywords
                # we should expect to see in the JSON that should be sent,
                # including the summary provided in the test call above.
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345' -and $Body -like '*update*labels*set*testLabel1*testLabel2*' }
            }

            It "Adds new labels if the Add parameter is supplied" {
                { Set-JiraIssueLabel -Issue TEST-001 -Add 'testLabel3' } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345' -and $Body -like '*update*labels*set*testLabel3*' }
            }

            It "Removes labels if the Remove parameter is supplied" {
                # The issue already has labels existingLabel1 and
                # existingLabel2. It should be set to just existingLabel2.
                { Set-JiraIssueLabel -Issue TEST-001 -Remove 'existingLabel1' } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345' -and $Body -like '*update*labels*set*existingLabel2*' }
            }

            It "Clears all labels if the Clear parameter is supplied" {
                { Set-JiraIssueLabel -Issue TEST-001 -Clear } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345' -and $Body -like '*update*labels*set*' }
            }

            It "Allows use of both Add and Remove parameters at the same time" {
                { Set-JiraIssueLabel -Issue TEST-001 -Add 'testLabel1' -Remove 'testLabel2' } | Should Not Throw
            }
        }

        Context "Input testing" {
            It "Accepts an issue key for the -Issue parameter" {
                { Set-JiraIssueLabel -Issue TEST-001 -Set 'testLabel1' } | Should Not Throw
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Accepts an issue object for the -Issue parameter" {
                $issue = Get-JiraIssue -Key TEST-001
                { Set-JiraIssueLabel -Issue $issue -Set 'testLabel1' } | Should Not Throw
                # Get-JiraIssue is called once explicitly in this test, and a
                # second time by Set-JiraIssue
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Accepts the output of Get-JiraIssue by pipeline for the -Issue paramete" {
                { Get-JiraIssue -Key TEST-001 | Set-JiraIssueLabel -Set 'testLabel1' } | Should Not Throw
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
        }
    }
}
