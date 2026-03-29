#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Remove-JiraGroup" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testGroupName = 'testGroup'

            $script:testJson = @"
{
    "name": "$testGroupName",
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
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraGroup -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraGroup' 'GroupName'
                $object = ConvertFrom-Json $testJson
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Group')
                return $object
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'DELETE' -and $URI -like "$jiraServer/rest/api/*/group?groupname=$testGroupName" } {
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
                $script:command = Get-Command -Name Remove-JiraGroup
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Group'; type = 'Object[]' }
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
            Context "Group Deletion" {
                It "Accepts a group name as a String to the -Group parameter" {
                    { Remove-JiraGroup -Group $testGroupName -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Accepts a JiraPS.Group object to the -Group parameter" {
                    $group = Get-JiraGroup -GroupName $testGroupName
                    { Remove-JiraGroup -Group $group -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Accepts pipeline input from Get-JiraGroup" {
                    { Get-JiraGroup -GroupName $testGroupName | Remove-JiraGroup -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Removes a group from JIRA" {
                    { Remove-JiraGroup -Group $testGroupName -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Provides no output" {
                    Remove-JiraGroup -Group $testGroupName -Force | Should -BeNullOrEmpty
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
