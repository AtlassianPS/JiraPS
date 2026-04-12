#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-CachedData" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $jiraServer = 'http://jiraserver.example.com'
            Mock Get-JiraConfigServer -ModuleName JiraPS { $jiraServer }
        }

        BeforeEach {
            $script:JiraCache = @{}
        }

        Describe "Cache Miss Behavior" {
            It "executes FetchScript and returns result when cache is empty" {
                $result = Get-CachedData -Key 'TestKey' -FetchScript { "FetchedValue" }

                $result | Should -Be "FetchedValue"
            }

            It "stores the result in the cache" {
                $null = Get-CachedData -Key 'TestKey' -FetchScript { "CachedValue" }

                $script:JiraCache.Keys | Should -Contain "TestKey:http://jiraserver.example.com"
                $script:JiraCache["TestKey:http://jiraserver.example.com"].Data | Should -Be "CachedValue"
            }

            It "sets an expiry time" {
                $null = Get-CachedData -Key 'TestKey' -ExpiryMinutes 30 -FetchScript { "Value" }

                $entry = $script:JiraCache["TestKey:http://jiraserver.example.com"]
                $entry.Expiry | Should -BeGreaterThan (Get-Date)
                $entry.Expiry | Should -BeLessThan (Get-Date).AddMinutes(31)
            }
        }

        Describe "Cache Hit Behavior" {
            It "returns cached data without executing FetchScript" {
                $script:JiraCache["TestKey:http://jiraserver.example.com"] = @{
                    Data   = "CachedValue"
                    Expiry = (Get-Date).AddMinutes(30)
                }

                $result = Get-CachedData -Key 'TestKey' -FetchScript { "NewValue" }

                $result | Should -Be "CachedValue"
            }

            It "executes FetchScript and returns fresh data when cache is expired" {
                $script:JiraCache["TestKey:http://jiraserver.example.com"] = @{
                    Data   = "ExpiredValue"
                    Expiry = (Get-Date).AddMinutes(-1)
                }

                $result = Get-CachedData -Key 'TestKey' -FetchScript { "FreshValue" }

                $result | Should -Be "FreshValue"
            }
        }

        Describe "Force Parameter" {
            It "bypasses cache and returns fresh data when -Force is specified" {
                $script:JiraCache["TestKey:http://jiraserver.example.com"] = @{
                    Data   = "CachedValue"
                    Expiry = (Get-Date).AddMinutes(30)
                }

                $result = Get-CachedData -Key 'TestKey' -Force -FetchScript { "ForcedValue" }

                $result | Should -Be "ForcedValue"
            }

            It "updates the cache when -Force is used" {
                $script:JiraCache["TestKey:http://jiraserver.example.com"] = @{
                    Data   = "OldValue"
                    Expiry = (Get-Date).AddMinutes(30)
                }

                $null = Get-CachedData -Key 'TestKey' -Force -FetchScript { "NewValue" }

                $script:JiraCache["TestKey:http://jiraserver.example.com"].Data | Should -Be "NewValue"
            }
        }

        Describe "Server-Specific Caching" {
            It "creates separate cache entries for different servers" {
                Mock Get-JiraConfigServer -ModuleName JiraPS { "http://server1.example.com" }
                $null = Get-CachedData -Key 'Fields' -FetchScript { "Server1Fields" }

                Mock Get-JiraConfigServer -ModuleName JiraPS { "http://server2.example.com" }
                $null = Get-CachedData -Key 'Fields' -FetchScript { "Server2Fields" }

                $script:JiraCache.Keys | Should -HaveCount 2
                $script:JiraCache["Fields:http://server1.example.com"].Data | Should -Be "Server1Fields"
                $script:JiraCache["Fields:http://server2.example.com"].Data | Should -Be "Server2Fields"
            }
        }
    }
}
