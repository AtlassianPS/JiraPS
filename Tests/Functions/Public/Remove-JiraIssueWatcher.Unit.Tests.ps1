#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

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
            Mock Resolve-JiraUser { [AtlassianPS.JiraPS.User]@{ Name = $InputObject.Name; AccountId = $InputObject.Name } }
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $object = [AtlassianPS.JiraPS.Issue]@{
                    ID      = $issueID
                    Key     = $issueKey
                    RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
                }
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject'
                Get-JiraIssue -Key $InputObject.Key
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'DELETE' -and
                $URI -eq "$jiraServer/rest/api/2/issue/$issueID/watchers" -and $GetParameter.ContainsKey('username')
            } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Uri', 'Method'
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Uri', 'Method'
                throw "Unidentified call to Invoke-JiraRequest"
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Watcher Removal" {
                It "removes a watcher from an existing issue" {
                    { Remove-JiraIssueWatcher -Watcher 'fred' -Issue $issueKey } | Should -Not -Throw
                    $WatcherResult = Remove-JiraIssueWatcher -Watcher 'fred' -Issue $issueKey
                    $WatcherResult | Should -BeNullOrEmpty

                    # Get-JiraIssue should be used to identify the issue parameter (called twice total)
                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2

                    # Invoke-JiraRequest should be used to remove the Watcher (called twice total)
                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 2 -ParameterFilter {
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
                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1
                }
            }
        }

        Describe "Input Validation" {
            Context "Multiple Watchers" {
                It "can remove multiple watchers" {
                    { Remove-JiraIssueWatcher -Watcher 'fred', 'george' -Issue $issueKey } | Should -Not -Throw
                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 2
                }
            }
        }

        Describe "Cloud Deployment" {
            BeforeAll {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Delete' -and $GetParameter.ContainsKey('accountId')
                } {
                    Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                }

                Mock Invoke-JiraRequest -ModuleName JiraPS {
                    Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                    throw "Unidentified call to Invoke-JiraRequest"
                }
            }

            It "uses accountId in the DELETE URI on Cloud" {
                $testAccountId = '5b10ac8d82e05b22cc7d4ef5'
                { Remove-JiraIssueWatcher -Issue 'TEST-001' -Watcher $testAccountId } | Should -Not -Throw

                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $Method -eq 'Delete' -and $GetParameter.accountId -eq $testAccountId
                }
            }
        }
    }
}
