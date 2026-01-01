#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertFrom-URLEncoded" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:sampleEncoded = "Hello%20World%3F"
            $script:expectedDecoded = 'Hello World?'
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Signature" {
            Context "Parameter Types" {
                # TODO: Add parameter type validation tests
            }
            Context "Default Values" {
                # TODO: Add default value validation tests
            }
            Context "Mandatory Parameters" {
                # TODO: Add mandatory parameter validation tests
            }
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertFrom-URLEncoded -InputString $sampleEncoded
                }

                It "returns decoded string" {
                    $result | Should -Not -BeNullOrEmpty
                    $result | Should -BeOfType [string]
                    $result | Should -Be $expectedDecoded
                }
            }

            Context "Property Mapping" {
                It "has InputString parameter" {
                    $command = Get-Command -Name ConvertFrom-URLEncoded
                    $command.Parameters.Keys | Should -Contain 'InputString'
                }

                It "returns as many objects as inputs provided" {
                    $r1 = ConvertFrom-URLEncoded -InputString "lorem"
                    $r2 = "lorem", "ipsum" | ConvertFrom-URLEncoded
                    $r3 = ConvertFrom-URLEncoded -InputString "lorem", "ipsum", "dolor"

                    @($r1) | Should -HaveCount 1
                    @($r2) | Should -HaveCount 2
                    @($r3) | Should -HaveCount 3
                }
            }
            Describe "Input Validation" {
                Context "Type Validation - Positive Cases" {
                    It "accepts pipeline input" {
                        { "lorem ipsum" | ConvertFrom-URLEncoded } | Should -Not -Throw
                    }

                    It "accepts multiple InputStrings" {
                        { ConvertFrom-URLEncoded -InputString "lorem", "ipsum" } | Should -Not -Throw
                        { "lorem", "ipsum" | ConvertFrom-URLEncoded } | Should -Not -Throw
                    }
                }
                Context "Type Validation - Negative Cases" {
                    It "does not allow null or empty input" {
                        { ConvertFrom-URLEncoded -InputString $null } | Should -Throw
                        { ConvertFrom-URLEncoded -InputString "" } | Should -Throw
                    }
                }
            }
        }
    }
}
