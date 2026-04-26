#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Set-JiraResponseHeaderLogConfiguration" -Tag 'Unit' {
        BeforeEach {
            $script:JiraResponseHeaderLogConfiguration = $null
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Set-JiraResponseHeaderLogConfiguration
            }

            It "has a parameter '<parameter>'" -TestCases @(
                @{ parameter = 'Include' }
                @{ parameter = 'Exclude' }
                @{ parameter = 'Pattern' }
                @{ parameter = 'Disable' }
            ) {
                param($parameter)

                $command | Should -HaveParameter $parameter
            }

            It "uses a Regex parameter for Pattern" {
                $command.Parameters.Pattern.ParameterType.FullName | Should -Be 'System.Text.RegularExpressions.Regex'
            }
        }

        Describe "Wildcard Configuration" {
            It "stores Include and Exclude patterns that drive the matcher" {
                Set-JiraResponseHeaderLogConfiguration -Include 'X-A*' -Exclude 'X-Auth*'

                $config = $script:JiraResponseHeaderLogConfiguration
                $config.Mode | Should -Be 'Wildcard'
                Test-JiraResponseHeaderMatch -Configuration $config -Name 'X-AREQUESTID' | Should -BeTrue
                Test-JiraResponseHeaderMatch -Configuration $config -Name 'X-Auth-Token' | Should -BeFalse
                Test-JiraResponseHeaderMatch -Configuration $config -Name 'Server' | Should -BeFalse
            }

            It "exposes the original Include and Exclude strings on the configuration" {
                Set-JiraResponseHeaderLogConfiguration -Include 'X-A*', 'X-Trace-*' -Exclude 'X-Auth*'

                $config = $script:JiraResponseHeaderLogConfiguration
                $config.Include | Should -Be @('X-A*', 'X-Trace-*')
                $config.Exclude | Should -Be @('X-Auth*')
            }

            It "accepts multiple Include patterns" {
                Set-JiraResponseHeaderLogConfiguration -Include 'X-A*', 'X-Trace-*'

                $config = $script:JiraResponseHeaderLogConfiguration
                Test-JiraResponseHeaderMatch -Configuration $config -Name 'X-AREQUESTID' | Should -BeTrue
                Test-JiraResponseHeaderMatch -Configuration $config -Name 'X-Trace-Id' | Should -BeTrue
                Test-JiraResponseHeaderMatch -Configuration $config -Name 'Server' | Should -BeFalse
            }

            It "warns when Include may log sensitive headers" {
                $warning = Set-JiraResponseHeaderLogConfiguration -Include '*' 3>&1

                ($warning | Out-String) | Should -Match 'sensitive headers'
            }

            It "warns when Include matches Authorization" {
                $warning = Set-JiraResponseHeaderLogConfiguration -Include 'Auth*' 3>&1

                ($warning | Out-String) | Should -Match 'sensitive headers'
            }

            It "does not warn when Exclude removes the sensitive match" {
                $warning = Set-JiraResponseHeaderLogConfiguration -Include 'X-A*' -Exclude 'X-Auth*' 3>&1

                $warning | Should -BeNullOrEmpty
            }
        }

        Describe "Regex Configuration" {
            It "stores a case-insensitive Regex configuration" {
                Set-JiraResponseHeaderLogConfiguration -Pattern '^x-a(?!uth)'

                $config = $script:JiraResponseHeaderLogConfiguration
                $config.Mode | Should -Be 'Regex'
                Test-JiraResponseHeaderMatch -Configuration $config -Name 'X-AREQUESTID' | Should -BeTrue
                Test-JiraResponseHeaderMatch -Configuration $config -Name 'X-Auth-Token' | Should -BeFalse
            }

            It "exposes the regex pattern on the configuration via ToString" {
                Set-JiraResponseHeaderLogConfiguration -Pattern '^X-A'

                $config = $script:JiraResponseHeaderLogConfiguration
                $config.Pattern.ToString() | Should -Be '^X-A'
            }

            It "warns when the pattern may log sensitive headers" {
                $warning = Set-JiraResponseHeaderLogConfiguration -Pattern '^Set-Cookie' 3>&1

                ($warning | Out-String) | Should -Match 'sensitive headers'
            }
        }

        Describe "Disable Configuration" {
            It "clears the module-scoped configuration" {
                Set-JiraResponseHeaderLogConfiguration -Include 'X-Trace-*'

                Set-JiraResponseHeaderLogConfiguration -Disable

                $script:JiraResponseHeaderLogConfiguration | Should -BeNullOrEmpty
            }
        }
    }
}
