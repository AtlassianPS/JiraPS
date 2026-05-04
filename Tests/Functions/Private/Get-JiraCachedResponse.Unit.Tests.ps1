#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

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
            Mock Get-JiraConfigServer -ModuleName 'JiraPS' { 'https://jira.example.com' }
        }

        It "returns null when cache should be bypassed" {
            $script:JiraCache['Fields:https://jira.example.com'] = @{
                Data   = @{ id = 1 }
                Expiry = (Get-Date).AddMinutes(5)
            }

            $result = Get-JiraCachedResponse -CacheKey 'Fields' -BypassCache

            $result | Should -BeNullOrEmpty
        }

        It "returns null for non-GET methods" {
            $script:JiraCache['Fields:https://jira.example.com'] = @{
                Data   = @{ id = 1 }
                Expiry = (Get-Date).AddMinutes(5)
            }

            $result = Get-JiraCachedResponse -CacheKey 'Fields' -Method 'POST'

            $result | Should -BeNullOrEmpty
        }

        It "returns cached entry when present and not expired" {
            $entry = @{
                Data   = @{ id = 1 }
                Expiry = (Get-Date).AddMinutes(5)
            }
            $script:JiraCache['Fields:https://jira.example.com'] = $entry

            $result = Get-JiraCachedResponse -CacheKey 'Fields'

            $result | Should -Be $entry
        }
    }
}
