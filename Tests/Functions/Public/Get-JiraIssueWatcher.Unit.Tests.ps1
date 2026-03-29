#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraIssueWatcher" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'https://jiraserver.example.com'
            $script:issueID = 41701
            $script:issueKey = 'IT-3676'

            ## Sample straight from the API:
            ##    https://docs.atlassian.com/jira/REST/cloud/#api/2/issue-getIssueWatchers
            $script:restResult = @"
{
    "self": "$jiraServer/jira/rest/api/2/issue/EX-1/watchers",
    "isWatching": false,
    "watchCount": 1,
    "watchers": [
        {
            "self": "$jiraServer/jira/rest/api/2/user?username=fred",
            "name": "fred",
            "displayName": "Fred F. User",
            "active": false
        }
    ]
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue'
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

            # Obtaining watchers from an issue...this is IT-3676 in the test environment
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/watchers" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $restResult
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Uri', 'Method'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            Context "Parameter Types" {
                # TODO: Add parameter type validation tests
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "Obtains all Jira watchers from a Jira issue if the issue key is provided" {
                $watchers = Get-JiraIssueWatcher -Issue $issueKey
                $watchers | Should -Not -BeNullOrEmpty
                @($watchers) | Should -HaveCount 1
                $watchers.Name | Should -Be "fred"
                $watchers.DisplayName | Should -Be "Fred F. User"
                $watchers.self | Should -Be "$jiraServer/jira/rest/api/2/user?username=fred"

                # Get-JiraIssue should be called to identify the -Issue parameter
                Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly 1

                # Normally, this would be called once in Get-JiraIssue and a second time in Get-JiraIssueWatcher, but
                # since we've mocked Get-JiraIssue out, it will only be called once.
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1
            }

            It "Obtains all Jira watchers from a Jira issue if the Jira object is provided" {
                $issue = Get-JiraIssue -Key $issueKey
                $watchers = Get-JiraIssueWatcher -Issue $issue
                $watchers | Should -Not -BeNullOrEmpty
                $watchers.name | Should -Be "fred"
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1
            }

            It "Handles pipeline input from Get-JiraIssue" {
                $watchers = Get-JiraIssue -Key $issueKey | Get-JiraIssueWatcher
                $watchers | Should -Not -BeNullOrEmpty
                $watchers.name | Should -Be "fred"
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
