#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Set-JiraIssueLabel" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'https://jira.example.com'
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $object = [PSCustomObject] @{
                    'Id'      = 123
                    'RestURL' = "$jiraServer/rest/api/2/issue/12345"
                    'Labels'  = @('existingLabel1', 'existingLabel2')
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'Issue'
                Get-JiraIssue -Key $Issue
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq "Put" -and $Uri -like "$jiraServer/rest/api/*/issue/12345" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Set-JiraIssueLabel
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Issue'; type = 'Object[]' }
                    @{ parameter = 'Set'; type = 'String[]' }
                    @{ parameter = 'Add'; type = 'String[]' }
                    @{ parameter = 'Remove'; type = 'String[]' }
                    @{ parameter = 'Clear'; type = 'SwitchParameter' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter
                    $command.Parameters[$parameter].ParameterType.Name | Should -Be $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "Replaces all issue labels if the Set parameter is supplied" {
                { Set-JiraIssueLabel -Issue TEST-001 -Set 'testLabel1', 'testLabel2' } | Should -Not -Throw
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Put' -and
                    $URI -like '*/rest/api/2/issue/12345' -and
                    $Body -like '*update*labels*set*testLabel1*testLabel2*'
                }
            }

            It "Adds new labels if the Add parameter is supplied" {
                { Set-JiraIssueLabel -Issue TEST-001 -Add 'testLabel3' } | Should -Not -Throw
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Put' -and
                    $URI -like '*/rest/api/2/issue/12345' -and
                    $Body -like '*update*labels*set*testLabel3*'
                }
            }

            It "Removes labels if the Remove parameter is supplied" {
                { Set-JiraIssueLabel -Issue TEST-001 -Remove 'existingLabel1' } | Should -Not -Throw
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Put' -and
                    $URI -like '*/rest/api/2/issue/12345' -and
                    $Body -like '*update*labels*set*existingLabel2*'
                }
            }

            It "Clears all labels if the Clear parameter is supplied" {
                { Set-JiraIssueLabel -Issue TEST-001 -Clear } | Should -Not -Throw
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Put' -and
                    $URI -like '*/rest/api/2/issue/12345' -and
                    $Body -like '*update*labels*set*'
                }
            }

            It "Allows use of both Add and Remove parameters at the same time" {
                { Set-JiraIssueLabel -Issue TEST-001 -Add 'testLabel1' -Remove 'testLabel2' } | Should -Not -Throw
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                It "Accepts an issue key for the -Issue parameter" {
                    { Set-JiraIssueLabel -Issue TEST-001 -Set 'testLabel1' } | Should -Not -Throw
                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "Accepts an issue object for the -Issue parameter" {
                    $issue = Get-JiraIssue -Key TEST-001
                    { Set-JiraIssueLabel -Issue $issue -Set 'testLabel1' } | Should -Not -Throw
                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "Accepts the output of Get-JiraIssue by pipeline for the -Issue parameter" {
                    { Get-JiraIssue -Key TEST-001 | Set-JiraIssueLabel -Set 'testLabel1' } | Should -Not -Throw
                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }

            Context "Negative cases" {
                # TODO: Add negative input validation tests
            }
        }
    }
}
