#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Test-JiraResponseHeaderMatch" -Tag 'Unit' {
        BeforeAll {
            $script:wildcardConfig = [PSCustomObject]@{
                Mode    = 'Wildcard'
                Include = @('X-A*')
                Exclude = @('X-Auth*')
            }

            $script:regexConfig = [PSCustomObject]@{
                Mode    = 'Regex'
                Pattern = [Regex]::new('^x-a(?!uth)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            }
        }

        Context "Wildcard mode" {
            It "returns true when Include matches and Exclude does not" {
                Test-JiraResponseHeaderMatch -Configuration $wildcardConfig -Name 'X-AREQUESTID' | Should -BeTrue
            }

            It "returns false when Exclude matches an Include hit" {
                Test-JiraResponseHeaderMatch -Configuration $wildcardConfig -Name 'X-Auth-Token' | Should -BeFalse
            }

            It "returns false when no Include pattern matches" {
                Test-JiraResponseHeaderMatch -Configuration $wildcardConfig -Name 'Server' | Should -BeFalse
            }

            It "matches case-insensitively" {
                Test-JiraResponseHeaderMatch -Configuration $wildcardConfig -Name 'x-anodeid' | Should -BeTrue
            }
        }

        Context "Regex mode" {
            It "returns true when the pattern matches" {
                Test-JiraResponseHeaderMatch -Configuration $regexConfig -Name 'X-AREQUESTID' | Should -BeTrue
            }

            It "returns false when the pattern excludes via lookahead" {
                Test-JiraResponseHeaderMatch -Configuration $regexConfig -Name 'X-Auth-Token' | Should -BeFalse
            }

            It "matches case-insensitively" {
                Test-JiraResponseHeaderMatch -Configuration $regexConfig -Name 'x-anodeid' | Should -BeTrue
            }
        }
    }
}
