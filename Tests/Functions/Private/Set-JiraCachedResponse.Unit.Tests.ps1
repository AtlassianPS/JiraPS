#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

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
            Mock Get-JiraConfigServer -ModuleName 'JiraPS' { 'https://jira.example.com' }
        }

        It "stores response in cache for GET requests" {
            $response = [PSCustomObject]@{ name = 'field' }

            Set-JiraCachedResponse -CacheKey 'Fields' -Method 'GET' -Response $response -CacheExpiry ([TimeSpan]::FromMinutes(5))

            $script:JiraCache.ContainsKey('Fields:https://jira.example.com') | Should -BeTrue
            $script:JiraCache['Fields:https://jira.example.com'].Data | Should -Be $response
        }

        It "does not cache non-GET requests" {
            $response = [PSCustomObject]@{ name = 'field' }

            Set-JiraCachedResponse -CacheKey 'Fields' -Method 'POST' -Response $response -CacheExpiry ([TimeSpan]::FromMinutes(5))

            $script:JiraCache.Count | Should -Be 0
        }
    }
}
