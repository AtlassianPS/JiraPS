#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-GetParameter" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        }

        Describe "Behavior" {
            Context "Empty input" {
                It "returns an empty string for an empty hashtable" {
                    ConvertTo-GetParameter @{} | Should -Be ''
                }
            }

            Context "Simple key/value pairs" {
                It "prefixes the result with '?' and joins pairs with '&'" {
                    $result = ConvertTo-GetParameter @{ a = 1; b = 2 }

                    $result | Should -Match '^\?'
                    $result.TrimStart('?').Split('&') | Should -HaveCount 2
                }

                It "encodes a single ASCII pair without changing it" {
                    ConvertTo-GetParameter @{ key = 'value' } | Should -Be '?key=value'
                }

                It "stringifies non-string values" {
                    ConvertTo-GetParameter @{ maxResults = 50 } | Should -Be '?maxResults=50'
                }
            }

            Context "URL encoding of values" {
                It "encodes spaces" {
                    # HttpUtility.UrlEncode uses '+' for space (form-style); both
                    # '+' and '%20' are accepted by Jira's REST API.
                    ConvertTo-GetParameter @{ jql = 'foo bar' } | Should -Be '?jql=foo+bar'
                }

                It "encodes the '&' separator inside a value" {
                    # Without encoding this would produce '?groupName=Dev & QA'
                    # which Jira would parse as three separate parameters.
                    ConvertTo-GetParameter @{ groupName = 'Dev & QA' } |
                        Should -Be '?groupName=Dev+%26+QA'
                }

                It "encodes '=' inside a value so the next 'key=value' parser is unambiguous" {
                    ConvertTo-GetParameter @{ jql = 'project=TEST' } |
                        Should -Be '?jql=project%3dTEST'
                }

                It "encodes '?', '#', '+', '%' reserved characters" {
                    ConvertTo-GetParameter @{ q = 'a?b#c+d%e' } |
                        Should -Be '?q=a%3fb%23c%2bd%25e'
                }

                It "encodes non-ASCII characters as UTF-8 percent escapes" {
                    # 'Müller' -> M %c3%bc ller
                    ConvertTo-GetParameter @{ name = 'Müller' } |
                        Should -Be '?name=M%c3%bcller'
                }

                It "encodes a JQL clause containing space, parens, comma and operators" {
                    $jql = 'reporter in (testuser)'
                    ConvertTo-GetParameter @{ jql = $jql } |
                        Should -Be '?jql=reporter+in+(testuser)'
                }
            }

            Context "URL encoding of keys" {
                It "encodes reserved characters in the key" {
                    ConvertTo-GetParameter @{ 'weird key&name' = 'v' } |
                        Should -Be '?weird+key%26name=v'
                }
            }

            Context "Null and empty values" {
                It "emits 'key=' for a `$null value" {
                    ConvertTo-GetParameter @{ flag = $null } | Should -Be '?flag='
                }

                It "emits 'key=' for an empty-string value" {
                    ConvertTo-GetParameter @{ flag = '' } | Should -Be '?flag='
                }
            }

            Context "Pipeline support" {
                It "accepts the hashtable from the pipeline" {
                    @{ key = 'value' } | ConvertTo-GetParameter | Should -Be '?key=value'
                }
            }

            Context "Round-trip with ConvertTo-ParameterHash" {
                It "preserves values containing reserved characters" {
                    $original = @{
                        jql       = 'project = TEST AND summary ~ "foo & bar"'
                        groupName = 'Dev & QA'
                        unicode   = 'Müller'
                    }

                    $query = ConvertTo-GetParameter $original
                    $parsed = ConvertTo-ParameterHash -Query $query

                    $parsed.jql       | Should -Be $original.jql
                    $parsed.groupName | Should -Be $original.groupName
                    $parsed.unicode   | Should -Be $original.unicode
                }
            }
        }
    }
}
