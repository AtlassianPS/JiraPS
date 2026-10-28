#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

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
                "connection-server1:http://server1.example.com:Fields"     = @{ Data = "Fields1"; Expiry = (Get-Date).AddHours(1) }
                "connection-server2:http://server2.example.com:Fields"     = @{ Data = "Fields2"; Expiry = (Get-Date).AddHours(1) }
                "connection-server1:http://server1.example.com:IssueTypes" = @{ Data = "Types1"; Expiry = (Get-Date).AddHours(1) }
                "connection-server1:http://server1.example.com:ServerInfo" = @{ Data = "Info1"; Expiry = (Get-Date).AddHours(1) }
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

                $script:JiraCache.Keys | Should -Not -Contain "connection-server1:http://server1.example.com:Fields"
                $script:JiraCache.Keys | Should -Not -Contain "connection-server2:http://server2.example.com:Fields"
                $script:JiraCache.Keys | Should -Contain "connection-server1:http://server1.example.com:IssueTypes"
                $script:JiraCache.Keys | Should -Contain "connection-server1:http://server1.example.com:ServerInfo"
            }

            It "clears only 'IssueTypes' entries" {
                Clear-JiraCache -Type IssueTypes

                $script:JiraCache.Keys | Should -Contain "connection-server1:http://server1.example.com:Fields"
                $script:JiraCache.Keys | Should -Not -Contain "connection-server1:http://server1.example.com:IssueTypes"
            }

            It "clears only 'ServerInfo' entries" {
                Clear-JiraCache -Type ServerInfo

                $script:JiraCache.Keys | Should -Contain "connection-server1:http://server1.example.com:Fields"
                $script:JiraCache.Keys | Should -Not -Contain "connection-server1:http://server1.example.com:ServerInfo"
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
