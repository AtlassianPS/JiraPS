#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Remove-JiraGroup" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testGroupName = 'testGroup'
            $script:testGroupId = '276f955c-63d7-42c8-9520-92d01dca0625'

            $script:testJson = @"
{
    "name": "$testGroupName",
    "groupId": "$testGroupId",
    "self": "$jiraServer/rest/api/2/group?groupname=$testGroupName",
    "users": {
        "size": 0,
        "items": [],
        "max-results": 50,
        "start-index": 0,
        "end-index": 0
    },
    "expand": "users"
}
"@
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            Mock Get-JiraGroup -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraGroup' 'GroupName'
                $object = ConvertFrom-Json $testJson
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Group')
                return $object
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'DELETE' -and
                $URI -eq '/rest/api/2/group' -and
                $GetParameter['groupname'] -eq $testGroupName
            } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri', 'GetParameter'
                # This REST method should produce no output
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Remove-JiraGroup
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Group'; type = 'AtlassianPS.JiraPS.Group[]' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Group Deletion" {
                It "Accepts a group name as a String to the -Group parameter" {
                    { Remove-JiraGroup -Group $testGroupName -Confirm:$false } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraRequest -Exactly -Times 1
                }

                It "Accepts a JiraPS.Group object to the -Group parameter" {
                    $group = Get-JiraGroup -GroupName $testGroupName
                    { Remove-JiraGroup -Group $group -Confirm:$false } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraRequest -Exactly -Times 1
                }

                It "Accepts pipeline input from Get-JiraGroup" {
                    { Get-JiraGroup -GroupName $testGroupName | Remove-JiraGroup -Confirm:$false } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraRequest -Exactly -Times 1
                }

                It "Removes a group from JIRA" {
                    { Remove-JiraGroup -Group $testGroupName -Confirm:$false } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraRequest -Exactly -Times 1
                }

                It "Provides no output" {
                    Remove-JiraGroup -Group $testGroupName -Confirm:$false | Should -BeNullOrEmpty
                }

                It "uses groupId for deletion on Cloud" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                    Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'DELETE' -and
                        $URI -eq '/rest/api/2/group' -and
                        $GetParameter['groupId'] -eq $testGroupId
                    } {
                        Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri', 'GetParameter'
                    }

                    $group = Get-JiraGroup -GroupName $testGroupName

                    { Remove-JiraGroup -Group $group -Confirm:$false } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'DELETE' -and
                        $URI -eq '/rest/api/2/group' -and
                        $GetParameter['groupId'] -eq $testGroupId
                    }
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
