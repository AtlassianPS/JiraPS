#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraRemoteLink" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'https://jiraserver.example.com'
            $script:issueKey = 'MKY-1'

            $script:restResult = @"
{
    "id": 10000,
    "self": "$jiraServer/rest/api/2/issue/MKY-1/remotelink/10000",
    "globalId": "system=http://www.mycompany.com/support&id=1",
    "application": {
        "type": "com.acme.tracker",
        "name": "My Acme Tracker"
    },
    "relationship": "causes",
    "object": {
        "url": "http://www.mycompany.com/support?id=1",
        "title": "TSTSUP-111",
        "summary": "Crazy customer support issue",
        "icon": {
            "url16x16": "http://www.mycompany.com/support/ticket.png",
            "title": "Support Ticket"
        }
    }
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Get-JiraIssue {
                Write-MockDebugInfo 'Get-JiraIssue'
                $object = [PSCustomObject] @{
                    'RestURL' = "$jiraServer/rest/api/2/issue/12345"
                    'Key'     = $issueKey
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'Issue'
                Get-JiraIssue -Key $Issue
            }

            Mock ConvertTo-JiraLink -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraLink'
                $InputObject
            }

            # Searching for a group.
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $restResult
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
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
            It "Gets information of all remote link from a Jira issue" {
                $getResult = Get-JiraRemoteLink -Issue $issueKey
                $getResult | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq "Get" -and
                    $Uri -like "$jiraServer/rest/api/*/issue/12345/remotelink"
                } -Exactly 1

                Should -Invoke ConvertTo-JiraLink -ModuleName JiraPS -Exactly 1
            }

            It "Gets information of all remote link from a Jira issue" {
                $getResult = Get-JiraRemoteLink -Issue $issueKey -LinkId 10000
                $getResult | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq "Get" -and
                    $Uri -like "$jiraServer/rest/api/*/issue/12345/remotelink/10000"
                } -Exactly 1
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
