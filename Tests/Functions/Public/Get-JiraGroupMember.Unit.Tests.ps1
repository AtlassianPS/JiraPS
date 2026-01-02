#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraGroupMember" -Tag 'Unit' {
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

            Mock Get-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraUser'
                $object = [PSCustomObject] @{
                    'Name' = 'username'
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
                return $object
            }

            Mock Get-JiraGroup -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraGroup'
                $obj = [PSCustomObject] @{
                    'Name'    = 'testgroup'
                    'RestUrl' = "$jiraServer/rest/api/2/group?groupname=testgroup"
                    'Size'    = 2
                }
                $obj.PSObject.TypeNames.Insert(0, 'JiraPS.Group')
                Write-Output $obj
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like '*/rest/api/*/group/member' -and $GetParameter["groupname"] -eq "testgroup" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json @'
{
"Name":  "testgroup",
"RestUrl":  "https://jira.example.com/rest/api/2/group?groupname=testgroup",
"Size":  2
}
'@
            }

            # If we don't override this in a context or test, we don't want it to
            # actually try to query a JIRA instance
            Mock Invoke-JiraMethod {
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
            It "Obtains members about a provided group in JIRA" {
                { Get-JiraGroupMember -Group testgroup } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName 'JiraPS' -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member'
                } -Exactly 1
            }

            It "Supports the -StartIndex parameters to page through search results" {
                { Get-JiraGroupMember -Group testgroup -StartIndex 10 } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName 'JiraPS' -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $Skip -eq 10
                } -Exactly 1
            }

            It "Supports the -MaxResults parameters to page through search results" {
                { Get-JiraGroupMember -Group testgroup -MaxResults 50 } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName 'JiraPS' -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $First -eq 50
                } -Exactly 1
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}

            It "Accepts a group name for the -Group parameter" {
                { Get-JiraGroupMember -Group testgroup } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName 'JiraPS' -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $GetParameter["groupname"] -eq "testgroup"
                } -Exactly 1
            }

            It "Accepts a group object for the -InputObject parameter" {
                $group = Get-JiraGroup -GroupName testgroup

                { Get-JiraGroupMember -Group $group } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName 'JiraPS' -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $GetParameter["groupname"] -eq "testgroup"
                } -Exactly 1

                # We called Get-JiraGroup once manually, and it should be
                # called once by Get-JiraGroupMember.
                Should -Invoke Get-JiraGroup -Exactly 2
            }
        }
    }
}
