#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Remove-JiraUser" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testUsername = 'powershell-test'
            $script:testEmail = "$testUsername@example.com"
            $script:testDisplayName = 'Test User'

            # Trimmed from this example JSON: expand, groups, avatarURL
            $script:testJsonGet = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "emailAddress": "$testEmail",
    "displayName": "$testDisplayName",
    "active": true
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraUser' 'UserName'
                $object = ConvertFrom-Json $testJsonGet
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
                return $object
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'DELETE' -and
                $URI -like "$jiraServer/rest/api/*/user?username=$testUsername"
            } {
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
                $script:command = Get-Command -Name Remove-JiraUser
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'User'; type = 'Object[]' }
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
            Context "User Deletion" {
                It "Accepts a username as a String to the -User parameter" {
                    { Remove-JiraUser -User $testUsername -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Accepts a JiraPS.User object to the -User parameter" {
                    $user = Get-JiraUser -UserName $testUsername
                    { Remove-JiraUser -User $user -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Accepts pipeline input from Get-JiraUser" {
                    { Get-JiraUser -UserName $testUsername | Remove-JiraUser -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Removes a user from JIRA" {
                    { Remove-JiraUser -User $testUsername -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
                }

                It "Provides no output" {
                    Remove-JiraUser -User $testUsername -Force | Should -BeNullOrEmpty
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
