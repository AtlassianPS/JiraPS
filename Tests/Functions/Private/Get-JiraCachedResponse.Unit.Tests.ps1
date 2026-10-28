#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Get-JiraCachedResponse" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        }

        BeforeEach {
            $script:JiraCache = @{}
            $script:cacheKey = '11111111-1111-1111-1111-111111111111:https://jira.example.com/rest/api/2/field:Fields'
        }

        It "returns null when cache should be bypassed" {
            $script:JiraCache[$cacheKey] = @{
                Data   = @{ id = 1 }
                Expiry = (Get-Date).AddMinutes(5)
            }

            $result = Get-JiraCachedResponse -CacheKey $cacheKey -BypassCache

            $result | Should -BeNullOrEmpty
        }

        It "returns null for non-GET methods" {
            $script:JiraCache[$cacheKey] = @{
                Data   = @{ id = 1 }
                Expiry = (Get-Date).AddMinutes(5)
            }

            $result = Get-JiraCachedResponse -CacheKey $cacheKey -Method 'POST'

            $result | Should -BeNullOrEmpty
        }

        It "returns cached entry when present and not expired" {
            $entry = @{
                Data   = @{ id = 1 }
                Expiry = (Get-Date).AddMinutes(5)
            }
            $script:JiraCache[$cacheKey] = $entry

            $result = Get-JiraCachedResponse -CacheKey $cacheKey

            $result | Should -Be $entry
        }

        It 'removes an expired entry without returning its response' {
            $script:JiraCache[$cacheKey] = @{
                Data   = @{ id = 1 }
                Expiry = (Get-Date).AddMinutes(-1)
            }

            Get-JiraCachedResponse -CacheKey $cacheKey | Should -BeNullOrEmpty
            $script:JiraCache.ContainsKey($cacheKey) | Should -BeFalse
        }
    }
}
