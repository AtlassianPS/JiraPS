#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-URLEncoded" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:sampleString = 'Hello World?'
            $script:expectedEncoded = "Hello+World%3F"
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-URLEncoded -InputString $sampleString
                }

                It "returns encoded string" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "encodes strings to URL format correctly" {
                    $result | Should -Be $expectedEncoded
                }
            }

            Context "Property Mapping" {
                It "has InputString parameter" {
                    $command = Get-Command -Name ConvertTo-URLEncoded
                    $command.Parameters.Keys | Should -Contain 'InputString'
                }

                It "returns as many objects as inputs provided" {
                    $r1 = ConvertTo-URLEncoded -InputString "lorem"
                    $r2 = "lorem", "ipsum" | ConvertTo-URLEncoded
                    $r3 = ConvertTo-URLEncoded -InputString "lorem", "ipsum", "dolor"

                    @($r1) | Should -HaveCount 1
                    @($r2) | Should -HaveCount 2
                    @($r3) | Should -HaveCount 3
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-URLEncoded -InputString $sampleString
                }

                It "returns string type" {
                    $result | Should -BeOfType [string]
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    { "lorem ipsum" | ConvertTo-URLEncoded } | Should -Not -Throw
                }

                It "accepts multiple InputStrings" {
                    { ConvertTo-URLEncoded -InputString "lorem", "ipsum" } | Should -Not -Throw
                    { "lorem", "ipsum" | ConvertTo-URLEncoded } | Should -Not -Throw
                }

                It "does not allow null or empty input" {
                    { ConvertTo-URLEncoded -InputString $null } | Should -Throw
                    { ConvertTo-URLEncoded -InputString "" } | Should -Throw
                }
            }
        }
    }
}
