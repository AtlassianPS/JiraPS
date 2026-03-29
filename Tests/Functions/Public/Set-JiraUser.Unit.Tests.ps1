#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Set-JiraUser" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testUsername = 'powershell-test'
            $script:testDisplayName = 'PowerShell Test User'
            $script:testEmail = "$testUsername@example.com"
            $script:testDisplayNameChanged = "$testDisplayName Modified"
            $script:testEmailChanged = "$testUsername@example2.com"

            $script:restResultGet = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "displayName": "$testDisplayName",
    "emailAddress": "$testEmail",
    "active": true
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Get-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraUser' 'UserName'
                $object = ConvertFrom-Json $restResultGet
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
                return $object
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' -and $URI -eq "$jiraServer/rest/api/2/user?username=$testUsername" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResultGet
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Set-JiraUser
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'User'; type = 'Object[]' }
                    @{ parameter = 'DisplayName'; type = 'String' }
                    @{ parameter = 'EmailAddress'; type = 'String' }
                    @{ parameter = 'Active'; type = 'Boolean' }
                    @{ parameter = 'PassThru'; type = 'SwitchParameter' }
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
            It "Accepts a username as a String to the -User parameter" {
                { Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged } | Should -Not -Throw
                Should -Invoke Get-JiraUser -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Accepts a JiraPS.User object to the -User parameter" {
                $user = Get-JiraUser -UserName $testUsername
                { Set-JiraUser -User $user -DisplayName $testDisplayNameChanged } | Should -Not -Throw
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Accepts pipeline input from Get-JiraUser" {
                { Get-JiraUser -UserName $testUsername | Set-JiraUser -DisplayName $testDisplayNameChanged } | Should -Not -Throw
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Modifies a user's DisplayName if the -DisplayName parameter is passed" {
                { Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged } | Should -Not -Throw
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Modifies a user's EmailAddress if the -EmailAddress parameter is passed" {
                { Set-JiraUser -User $testUsername -EmailAddress $testEmailChanged } | Should -Not -Throw
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Provides no output if the -PassThru parameter is not passed" {
                $output = Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged
                $output | Should -BeNullOrEmpty
            }

            It "Outputs a JiraPS.User object if the -PassThru parameter is passed" {
                $output = Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged -PassThru
                $output | Should -Not -BeNullOrEmpty
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
