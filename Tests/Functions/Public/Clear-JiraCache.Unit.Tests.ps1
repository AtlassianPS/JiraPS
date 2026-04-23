#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Clear-JiraCache" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        }

        BeforeEach {
            $script:JiraCache = @{
                "Fields:http://server1.example.com"     = @{ Data = "Fields1"; Expiry = (Get-Date).AddHours(1) }
                "Fields:http://server2.example.com"     = @{ Data = "Fields2"; Expiry = (Get-Date).AddHours(1) }
                "IssueTypes:http://server1.example.com" = @{ Data = "Types1"; Expiry = (Get-Date).AddHours(1) }
                "ServerInfo:http://server1.example.com" = @{ Data = "Info1"; Expiry = (Get-Date).AddHours(1) }
            }
        }

        Describe "Clear All Cache" {
            It "clears all cached items when Type is 'All'" {
                Clear-JiraCache -Type All

                $script:JiraCache.Count | Should -Be 0
            }

            It "clears all cached items by default" {
                Clear-JiraCache

                $script:JiraCache.Count | Should -Be 0
            }
        }

        Describe "Clear Specific Type" {
            It "clears only 'Fields' entries" {
                Clear-JiraCache -Type Fields

                $script:JiraCache.Keys | Should -Not -Contain "Fields:http://server1.example.com"
                $script:JiraCache.Keys | Should -Not -Contain "Fields:http://server2.example.com"
                $script:JiraCache.Keys | Should -Contain "IssueTypes:http://server1.example.com"
                $script:JiraCache.Keys | Should -Contain "ServerInfo:http://server1.example.com"
            }

            It "clears only 'IssueTypes' entries" {
                Clear-JiraCache -Type IssueTypes

                $script:JiraCache.Keys | Should -Contain "Fields:http://server1.example.com"
                $script:JiraCache.Keys | Should -Not -Contain "IssueTypes:http://server1.example.com"
            }

            It "clears only 'ServerInfo' entries" {
                Clear-JiraCache -Type ServerInfo

                $script:JiraCache.Keys | Should -Contain "Fields:http://server1.example.com"
                $script:JiraCache.Keys | Should -Not -Contain "ServerInfo:http://server1.example.com"
            }
        }

        Describe "Empty Cache Handling" {
            It "handles empty cache gracefully" {
                $script:JiraCache = @{}

                { Clear-JiraCache } | Should -Not -Throw
            }

            It "handles null cache gracefully" {
                $script:JiraCache = $null

                { Clear-JiraCache } | Should -Not -Throw
            }
        }

        Describe "Type Validation" {
            It "accepts valid Type values" -TestCases @(
                @{ Type = 'All' }
                @{ Type = 'Fields' }
                @{ Type = 'IssueTypes' }
                @{ Type = 'Priorities' }
                @{ Type = 'Statuses' }
                @{ Type = 'ServerInfo' }
            ) {
                { Clear-JiraCache -Type $Type } | Should -Not -Throw
            }
        }
    }
}
