#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Set-JiraConfigServer" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            #endregion Definitions

            #region Mocks
            # No mocks needed for this simple function
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Set-JiraConfigServer
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Server'; type = 'Uri' }
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
            It "stores the server address in the module session" {
                Set-JiraConfigServer -Server $jiraServer

                $script:JiraServerUrl | Should -Be "$jiraServer/"
            }

            It "stores the server address in a config file" {
                $script:serverConfig | Should -Exist

                Get-Content $script:serverConfig | Should -Be "$jiraServer/"
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
