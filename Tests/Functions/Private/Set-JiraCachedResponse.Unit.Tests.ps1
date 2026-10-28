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
        }

        It "stores response in cache for GET requests" {
            $response = [PSCustomObject]@{ name = 'field' }

            Set-JiraCachedResponse -CacheKey 'Fields' -Method 'GET' -Response $response -CacheExpiry ([TimeSpan]::FromMinutes(5))

            $script:JiraCache.ContainsKey('Fields') | Should -BeTrue
            $script:JiraCache['Fields'].Data | Should -Be $response
        }

        It "does not cache non-GET requests" {
            $response = [PSCustomObject]@{ name = 'field' }

            Set-JiraCachedResponse -CacheKey 'Fields' -Method 'POST' -Response $response -CacheExpiry ([TimeSpan]::FromMinutes(5))

            $script:JiraCache.Count | Should -Be 0
        }
    }
}
