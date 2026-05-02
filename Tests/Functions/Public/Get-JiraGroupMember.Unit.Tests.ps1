#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Get-JiraGroupMember" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'https://jira.example.com'
            $script:testGroupId = '276f955c-63d7-42c8-9520-92d01dca0625'
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraUser'
                $object = [PSCustomObject] @{
                    'Name' = 'username'
                }
                $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                return $object
            }

            Mock Get-JiraGroup -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraGroup'
                $obj = [PSCustomObject] @{
                    'Name'    = 'testgroup'
                    'Id'      = $testGroupId
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

            It "Supports the -Skip parameter to page through search results" {
                { Get-JiraGroupMember -Group testgroup -Skip 10 } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName 'JiraPS' -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $Skip -eq 10
                } -Exactly 1
            }

            It "Supports the -First parameter to limit search results" {
                { Get-JiraGroupMember -Group testgroup -First 50 } | Should -Not -Throw

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

                Should -Invoke Get-JiraGroup -Exactly 1
            }

            It "uses groupId for Cloud-compatible group lookups when the input group includes an Id" {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $GetParameter['groupId'] -eq $testGroupId
                } {
                    Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'GetParameter'
                    ConvertFrom-Json @'
{
  "isLast": true,
  "maxResults": 50,
  "startAt": 0,
  "total": 1,
  "values": [
    {
      "accountId": "abc123",
      "name": "",
      "displayName": "Test User",
      "active": true,
      "self": "https://jira.example.com/rest/api/2/user?accountId=abc123"
    }
  ]
}
'@
                }

                $group = Get-JiraGroup -GroupName testgroup

                { Get-JiraGroupMember -Group $group } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName 'JiraPS' -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $GetParameter['groupId'] -eq $testGroupId
                } -Exactly 1
            }

            It "uses groupname when the group input does not include an Id" {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                { Get-JiraGroupMember -Group testgroup } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName 'JiraPS' -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $GetParameter['groupname'] -eq 'testgroup'
                } -Exactly 1
            }

            It "uses groupname for Server lookups" {
                { Get-JiraGroupMember -Group testgroup } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName 'JiraPS' -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $GetParameter['groupname'] -eq 'testgroup'
                } -Exactly 1
            }
        }
    }
}
