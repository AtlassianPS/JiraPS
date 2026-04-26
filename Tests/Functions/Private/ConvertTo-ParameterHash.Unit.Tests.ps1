#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-ParameterHash" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        }

        Describe "Behavior" {
            Context "ByString" {
                It "returns an empty hashtable when the query has no leading '?'" {
                    $result = ConvertTo-ParameterHash -Query 'not-a-query-string'
                    $result | Should -BeOfType [Hashtable]
                    $result.Count | Should -Be 0
                }

                It "parses a single 'key=value' pair" {
                    $result = ConvertTo-ParameterHash -Query '?key=value'
                    $result['key'] | Should -Be 'value'
                }

                It "parses multiple pairs separated by '&'" {
                    $result = ConvertTo-ParameterHash -Query '?a=1&b=2&c=3'
                    $result['a'] | Should -Be '1'
                    $result['b'] | Should -Be '2'
                    $result['c'] | Should -Be '3'
                }

                It "URL-decodes the value (space encoded as '+')" {
                    $result = ConvertTo-ParameterHash -Query '?jql=foo+bar'
                    $result['jql'] | Should -Be 'foo bar'
                }

                It "URL-decodes the value (percent escapes)" {
                    $result = ConvertTo-ParameterHash -Query '?name=M%c3%bcller'
                    $result['name'] | Should -Be 'Müller'
                }

                It "preserves an '=' that is part of the value (split on first '=' only)" {
                    # Regression: the previous implementation called Split('=')
                    # without a limit, which truncated the value at the first
                    # '=' and ignored the rest. With Split('=', 2) the full
                    # value (including the '=' character) is preserved.
                    $result = ConvertTo-ParameterHash -Query '?jql=project%3dTEST'
                    $result['jql'] | Should -Be 'project=TEST'
                }

                It "handles an empty value ('key=')" {
                    $result = ConvertTo-ParameterHash -Query '?flag='
                    $result.ContainsKey('flag') | Should -BeTrue
                    $result['flag'] | Should -BeNullOrEmpty
                }

                It "lets the last value win when a key is repeated" {
                    # Prevents the 'item has already been added' exception that
                    # the previous Hashtable.Add() implementation threw.
                    $result = ConvertTo-ParameterHash -Query '?expand=a&expand=b'
                    $result['expand'] | Should -Be 'b'
                }
            }

            Context "ByUri" {
                It "uses the Query portion of the supplied [Uri]" {
                    [Uri]$uri = 'https://jira.example.com/rest/api/2/search?jql=foo+bar&maxResults=25'
                    $result = ConvertTo-ParameterHash -Uri $uri

                    $result['jql']        | Should -Be 'foo bar'
                    $result['maxResults'] | Should -Be '25'
                }

                It "returns an empty hashtable when the URI has no query" {
                    [Uri]$uri = 'https://jira.example.com/rest/api/2/search'
                    $result = ConvertTo-ParameterHash -Uri $uri
                    $result.Count | Should -Be 0
                }
            }
        }
    }
}
