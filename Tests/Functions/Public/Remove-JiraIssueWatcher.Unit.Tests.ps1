#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Remove-JiraIssueWatcher" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueID = 41701
            $script:issueKey = 'IT-3676'
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $object = [PSCustomObject] @{
                    ID      = $issueID
                    Key     = $issueKey
                    RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'Issue'
                Get-JiraIssue -Key $Issue
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'DELETE' -and
                $URI -like "$jiraServer/rest/api/2/issue/$issueID/watchers?username=*"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Uri', 'Method'
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Uri', 'Method'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Remove-JiraIssueWatcher
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Watcher'; type = 'String[]' }
                    @{ parameter = 'Issue'; type = 'Object' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Watcher Removal" {
                It "removes a watcher from an existing issue" {
                    { Remove-JiraIssueWatcher -Watcher 'fred' -Issue $issueKey } | Should -Not -Throw
                    $WatcherResult = Remove-JiraIssueWatcher -Watcher 'fred' -Issue $issueKey
                    $WatcherResult | Should -BeNullOrEmpty

                    # Get-JiraIssue should be used to identify the issue parameter (called twice total)
                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It

                    # Invoke-JiraMethod should be used to remove the Watcher (called twice total)
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It -ParameterFilter {
                        $Method -eq 'DELETE' -and
                        $URI -like "$jiraServer/rest/api/*/issue/$issueID/watchers*"
                    }
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input from Get-JiraIssue" {
                    $WatcherResult = Get-JiraIssue -Key $issueKey | Remove-JiraIssueWatcher -Watcher 'fred'
                    $WatcherResult | Should -BeNullOrEmpty

                    # Get-JiraIssue called once in test, once inside Remove-JiraIssueWatcher
                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Multiple Watchers" {
                It "can remove multiple watchers" {
                    { Remove-JiraIssueWatcher -Watcher 'fred', 'george' -Issue $issueKey } | Should -Not -Throw
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }
            }
        }
    }
}
