#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Remove-JiraRemoteLink" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testIssueKey = 'EX-1'

            $script:testLink = @"
{
    "id": 10000,
    "self": "http://www.example.com/jira/rest/api/issue/MKY-1/remotelink/10000",
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
                $jiraServer
            }

            Mock Get-JiraIssue {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $object = [PSCustomObject] @{
                    'RestURL' = 'https://jira.example.com/rest/api/2/issue/12345'
                    'Key'     = $testIssueKey
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'Issue'
                Get-JiraIssue -Key $Issue
            }

            Mock Get-JiraRemoteLink {
                Write-MockDebugInfo 'Get-JiraRemoteLink' 'Issue'
                $object = ConvertFrom-Json $testLink
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLinkType')
                return $object
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'DELETE' } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                # This REST method should produce no output
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
                $script:command = Get-Command -Name Remove-JiraRemoteLink
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Issue'; type = 'Object[]' }
                    @{ parameter = 'LinkId'; type = 'Int32[]' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                    @{ parameter = 'Force'; type = 'Switch' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Remote Link Deletion" {
                It "Accepts a issue key to the -Issue parameter" {
                    { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Accepts a JiraPS.Issue object to the -Issue parameter" {
                    $Issue = Get-JiraIssue $testIssueKey
                    { Remove-JiraRemoteLink -Issue $Issue -LinkId 10000 -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Accepts pipeline input from Get-JiraIssue" {
                    { Get-JiraIssue $testIssueKey | Remove-JiraRemoteLink -LinkId 10000 -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Accepts the output of Get-JiraRemoteLink" {
                    $remoteLink = Get-JiraRemoteLink $testIssueKey
                    { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId $remoteLink.id -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Removes a group from JIRA" {
                    { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Provides no output" {
                    Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force | Should -BeNullOrEmpty
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
