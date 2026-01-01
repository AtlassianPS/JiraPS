#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Remove-JiraIssueLink" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueLinkId = 1234
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraIssueLink -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssueLink' 'Id'
                $obj = [PSCustomObject]@{
                    "id"          = $issueLinkId
                    "type"        = "foo"
                    "inwardIssue" = "bar"
                }
                $obj.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLink')
                return $obj
            }

            Mock Get-JiraIssue -ModuleName JiraPS -ParameterFilter { $Key -eq "TEST-01" } {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                # We don't care about the content of any field except for the id of the issuelinks
                $issue = [PSCustomObject]@{
                    issueLinks = @( (Get-JiraIssueLink -Id 1234) )
                }
                $issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                return $issue
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/*/issueLink/1234" } {
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
                $script:command = Get-Command -Name Remove-JiraIssueLink
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'IssueLink'; type = 'Object[]' }
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
            Context "Issue Link Deletion" {
                It "Accepts generic object with the correct properties" {
                    $issueLink = Get-JiraIssueLink -Id 1234
                    $issue = Get-JiraIssue -Key TEST-01
                    { Remove-JiraIssueLink -IssueLink $issueLink } | Should -Not -Throw
                    { Remove-JiraIssueLink -IssueLink $issue } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 2 -Scope It
                }

                It "Accepts a JiraPS.Issue object over the pipeline" {
                    { Get-JiraIssue -Key TEST-01 | Remove-JiraIssueLink } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Accepts a JiraPS.IssueType over the pipeline" {
                    { Get-JiraIssueLink -Id 1234 | Remove-JiraIssueLink } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                # TODO: Add positive input validation tests
            }

            Context "Negative cases" {
                It "Validates pipeline input" {
                    { @{id = 1 } | Remove-JiraIssueLink -ErrorAction SilentlyContinue } | Should -Throw
                }
            }
        }
    }
}
