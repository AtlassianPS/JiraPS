#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "New-JiraUser" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testUsername = 'powershell-test'
            $script:testEmail = "$testUsername@example.com"
            $script:testDisplayName = 'Test User'

            # Trimmed from this example JSON: expand, groups, avatarURL
            $script:testJson = @"
{
    "self": "$jiraServer/rest/api/2/user?username=testUser",
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

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/user" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $testJson
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
                $script:command = Get-Command -Name New-JiraUser
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'UserName'; type = 'String' }
                    @{ parameter = 'EmailAddress'; type = 'String' }
                    @{ parameter = 'DisplayName'; type = 'String' }
                    @{ parameter = 'Notify'; type = 'Boolean' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter
                    $command.Parameters[$parameter].ParameterType.Name | Should -Be $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "Creates a user in JIRA and returns a result" {
                $newResult = New-JiraUser -UserName $testUsername -EmailAddress $testEmail -DisplayName $testDisplayName
                $newResult | Should -Not -BeNullOrEmpty
            }

            It "Uses ConvertTo-JiraUser to beautify output" {
                Mock ConvertTo-JiraUser {}
                New-JiraUser -UserName $testUsername -EmailAddress $testEmail -DisplayName $testDisplayName
                Should -Invoke 'ConvertTo-JiraUser' -ModuleName JiraPS -Exactly 1
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
