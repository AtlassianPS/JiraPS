#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Set-JiraCachedResponse" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        }

        BeforeEach {
            $script:JiraCache = @{}
            $script:cacheKey = '11111111-1111-1111-1111-111111111111:https://jira.example.com/rest/api/2/field:Fields'
        }

        It "stores response in cache for GET requests" {
            $response = [PSCustomObject]@{ name = 'field' }

            Set-JiraCachedResponse -CacheKey $cacheKey -Method 'GET' -Response $response -CacheExpiry ([TimeSpan]::FromMinutes(5))

            $script:JiraCache.ContainsKey($cacheKey) | Should -BeTrue
            $script:JiraCache[$cacheKey].Data | Should -Be $response
        }

        It "does not cache non-GET requests" {
            $response = [PSCustomObject]@{ name = 'field' }

            Set-JiraCachedResponse -CacheKey $cacheKey -Method 'POST' -Response $response -CacheExpiry ([TimeSpan]::FromMinutes(5))

            $script:JiraCache.Count | Should -Be 0
        }
    }
}
