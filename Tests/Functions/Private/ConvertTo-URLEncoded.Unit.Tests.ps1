#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-URLEncoded" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:sampleString = 'Hello World?'
            $script:expectedEncoded = "Hello%20World%3F"
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-URLEncoded -InputString $sampleString
                }

                It "encodes strings to URL format correctly" {
                    $result | Should -Be $expectedEncoded
                }
            }

            Context "Component encoding" {
                It "preserves reserved characters inside one segment" {
                    ConvertTo-URLEncoded -InputString 'In Progress/QA?#' |
                        Should -Be 'In%20Progress%2FQA%3F%23'
                }

                It "encodes literal plus and percent characters" {
                    ConvertTo-URLEncoded -InputString 'QA+50%' |
                        Should -Be 'QA%2B50%25'
                }

                It "encodes Unicode segments from the pipeline" {
                    $result = @('Prüfung', 'In Progress' | ConvertTo-URLEncoded)

                    $result | Should -HaveCount 2
                    $result[0] | Should -Be 'Pr%C3%BCfung'
                    $result[1] | Should -Be 'In%20Progress'
                }
            }

            Context "Long values" {
                It "encodes a value at the .NET Framework input limit" {
                    $prefix = 'a' * 32765

                    ConvertTo-URLEncoded ($prefix + ' ') | Should -BeExactly ($prefix + '%20')
                }

                It "encodes values spanning multiple chunks without truncation" {
                    $value = ('a' * 32766) + ' +/?#%' + ('b' * 32766)
                    $expected = ('a' * 32766) + '%20%2B%2F%3F%23%25' + ('b' * 32766)

                    ConvertTo-URLEncoded $value | Should -BeExactly $expected
                }

                It "keeps a Unicode surrogate pair together at a chunk boundary" {
                    $prefix = 'a' * 32765
                    $emoji = [char]::ConvertFromUtf32(0x1F600)
                    $value = $prefix + $emoji + ' tail'

                    ConvertTo-URLEncoded $value | Should -BeExactly ($prefix + '%F0%9F%98%80%20tail')
                }
            }

            Context "Property Mapping" {
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
                It "does not allow null or empty input" {
                    { ConvertTo-URLEncoded -InputString $null } | Should -Throw
                    { ConvertTo-URLEncoded -InputString "" } | Should -Throw
                }
            }
        }
    }
}
