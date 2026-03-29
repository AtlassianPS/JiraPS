#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraSession" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:sampleUsername = 'powershell-test'
            $script:sampleSession = @{}
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraSession -Session $sampleSession -Username $sampleUsername
                }

                It "creates PSObject from session data" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.Session'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.Session'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraSession -Session $sampleSession -Username $sampleUsername
                }

                It "defines 'Username' property with correct value" {
                    $result.Username | Should -Be $sampleUsername
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraSession -Session $sampleSession -Username $sampleUsername
                }

                It "converts Username to correct type" {
                    $result.Username | Should -BeOfType [string]
                }
            }

            Context "Pipeline Support" {
                It "accepts session parameter" {
                    $result = ConvertTo-JiraSession -Session $sampleSession -Username $sampleUsername
                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
