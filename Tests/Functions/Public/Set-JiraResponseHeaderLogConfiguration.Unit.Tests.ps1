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
            It "stores a matcher that respects Include and Exclude" {
                Set-JiraResponseHeaderLogConfiguration -Include 'X-A*' -Exclude 'X-Auth*'

                $match = $script:JiraResponseHeaderLogConfiguration.Match
                (& $match 'X-AREQUESTID') | Should -BeTrue
                (& $match 'X-Auth-Token') | Should -BeFalse
                (& $match 'Server') | Should -BeFalse
            }

            It "accepts multiple Include patterns" {
                Set-JiraResponseHeaderLogConfiguration -Include 'X-A*', 'X-Trace-*'

                $match = $script:JiraResponseHeaderLogConfiguration.Match
                (& $match 'X-AREQUESTID') | Should -BeTrue
                (& $match 'X-Trace-Id') | Should -BeTrue
                (& $match 'Server') | Should -BeFalse
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
            It "stores a case-insensitive matcher" {
                Set-JiraResponseHeaderLogConfiguration -Pattern '^x-a(?!uth)'

                $match = $script:JiraResponseHeaderLogConfiguration.Match
                (& $match 'X-AREQUESTID') | Should -BeTrue
                (& $match 'X-Auth-Token') | Should -BeFalse
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
