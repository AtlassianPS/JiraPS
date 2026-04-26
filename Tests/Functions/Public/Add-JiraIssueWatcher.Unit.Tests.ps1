#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Add-JiraIssueWatcher" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $jiraServer = 'http://jiraserver.example.com'
            $issueID = 41701
            $issueKey = 'IT-3676'
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

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

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/watchers" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Add-JiraIssueWatcher"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Watcher"; type = "String[]" }
                    @{ parameter = "Issue"; type = "Object" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                ) {
                    $command | Should -HaveParameter $parameter

                    #ToDo:CustomClass
                    # can't use -Type as long we are using `PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Filter')`
                    (Get-Member -InputObject $command.Parameters.Item($parameter)).Attributes | Should -Contain $typeName
                }
            }

            Context "Default Values" {
                It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                    @{ parameter = "Credential"; defaultValue = "[System.Management.Automation.PSCredential]::Empty" }
                ) {
                    $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "Watcher" }
                    @{ parameter = "Issue" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" {
            It "Adds a Watcher to an issue in JIRA" {
                $WatcherResult = Add-JiraIssueWatcher -Watcher 'fred' -Issue $issueKey
                $WatcherResult | Should -BeNullOrEmpty

                # Get-JiraIssue should be used to identify the issue parameter
                Should -Invoke -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1

                # Invoke-JiraMethod should be used to add the Watcher
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {
                It "Accepts pipeline input from Get-JiraIssue" {
                    $WatcherResult = Get-JiraIssue -Key $issueKey | Add-JiraIssueWatcher -Watcher 'fred'
                    $WatcherResult | Should -BeNullOrEmpty

                    # Get-JiraIssue should be called once here, and once inside Add-JiraIssueWatcher (to identify the InputObject parameter)
                    Should -Invoke -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
                }
            }

            Context "Type Validation - Negative Cases" {}
        }

        Describe "Cloud Deployment" {
            BeforeAll {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }
            }

            It "uses ConvertTo-Json for watcher body on Cloud" {
                # Use an accountId-like string as the watcher
                $testAccountId = '5b10ac8d82e05b22cc7d4ef5'
                { Add-JiraIssueWatcher -Issue 'TEST-001' -Watcher $testAccountId } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $Method -eq 'Post' -and $Body -eq (ConvertTo-Json -InputObject $testAccountId)
                }
            }
        }
    }
}
