#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraIssueWorklog" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueID = 41701
            $script:issueKey = 'IT-3676'

            $script:restResult = @"
{
    "startAt": 0,
    "maxResults": 1,
    "total": 1,
    "worklogs": [
        {
            "self": "$jiraServer/rest/api/2/issue/$issueID/worklog/90730",
            "id": "90730",
            "comment": "Test comment",
            "created": "2015-05-01T16:24:38.000-0500",
            "updated": "2015-05-01T16:24:38.000-0500",
            "visibility": {
                "type": "role",
                "value": "Developers"
            },
            "timeSpent": "3m",
            "timeSpentSeconds": 180
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

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/worklog" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                (ConvertFrom-Json -InputObject $restResult).worklogs
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
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
            Context "Behavior testing" {
                It "Obtains all Jira worklogs from a Jira issue if the issue key is provided" {
                    $worklogs = Get-JiraIssueWorklog -Issue $issueKey

                    $worklogs | Should -Not -BeNullOrEmpty
                    @($worklogs) | Should -HaveCount 1
                    $worklogs.ID | Should -Be 90730
                    $worklogs.Comment | Should -Be 'Test comment'
                    $worklogs.TimeSpent | Should -Be '3m'
                    $worklogs.TimeSpentSeconds | Should -Be 180

                    # Get-JiraIssue should be called to identify the -Issue parameter
                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It

                    # Normally, this would be called once in Get-JiraIssue and a second time in Get-JiraIssueComment, but
                    # since we've mocked Get-JiraIssue out, it will only be called once.
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "Obtains all Jira worklogs from a Jira issue if the Jira object is provided" {
                    $issue = Get-JiraIssue -Key $issueKey
                    $worklogs = Get-JiraIssueWorklog -Issue $issue

                    $worklogs | Should -Not -BeNullOrEmpty
                    $worklogs.ID | Should -Be 90730

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "Handles pipeline input from Get-JiraIssue" {
                    $worklogs = Get-JiraIssue -Key $issueKey | Get-JiraIssueWorklog

                    $worklogs | Should -Not -BeNullOrEmpty
                    $worklogs.ID | Should -Be 90730

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
