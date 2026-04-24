#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
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
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $object = [AtlassianPS.JiraPS.Issue]@{
                    ID = $issueID
                    Key = $issueKey
                    RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
                }
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject'
                Get-JiraIssue -Key $InputObject.Key
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
                    @{ parameter = 'Issue'; type = 'AtlassianPS.JiraPS.Issue' }
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
                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2

                    # Invoke-JiraMethod should be used to remove the Watcher (called twice total)
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -ParameterFilter {
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
                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
                }
            }
        }

        Describe "Input Validation" {
            Context "Multiple Watchers" {
                It "can remove multiple watchers" {
                    { Remove-JiraIssueWatcher -Watcher 'fred', 'george' -Issue $issueKey } | Should -Not -Throw
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2
                }
            }
        }

        Describe "Cloud Deployment" {
            BeforeAll {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Delete' -and $URI -match 'accountId='
                } {
                    Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                }

                Mock Invoke-JiraMethod -ModuleName JiraPS {
                    Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                    throw "Unidentified call to Invoke-JiraMethod"
                }
            }

            It "uses accountId in the DELETE URI on Cloud" {
                $testAccountId = '5b10ac8d82e05b22cc7d4ef5'
                { Remove-JiraIssueWatcher -Issue 'TEST-001' -Watcher $testAccountId } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $Method -eq 'Delete' -and $URI -match "accountId=$testAccountId"
                }
            }
        }
    }
}
