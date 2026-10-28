#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Get-JiraUser caller contract' -Tag Unit {
        BeforeEach {
            Mock Test-JiraCloudServer { $false }
            Mock Invoke-JiraRequest {
                [PSCustomObject]@{
                    name        = $GetParameter.username
                    accountId   = $GetParameter.accountId
                    displayName = 'Display name'
                    self        = 'https://jira.example.com/rest/api/2/user'
                    active      = $true
                }
            }
        }

        It 'looks up literal Data Center usernames exactly without a follow-up request' {
            $result = Get-JiraUser -User 'opaque user+name'
            $result.Name | Should -Be 'opaque user+name'
            Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter {
                $Uri -eq '/rest/api/2/user' -and $GetParameter.username -eq 'opaque user+name' -and $GetParameter.expand -eq 'groups'
            }
        }

        It 'uses opaque Cloud account IDs instead of their display names' {
            Mock Test-JiraCloudServer { $true }
            $user = [AtlassianPS.JiraPS.User]@{ AccountId = 'any:opaque value'; DisplayName = 'Human name' }
            $result = $user | Get-JiraUser
            $result.AccountId | Should -Be 'any:opaque value'
            Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter { $GetParameter.accountId -eq 'any:opaque value' }
        }

        It 'interprets Cloud string inputs as literal account IDs without guessing their format' {
            Mock Test-JiraCloudServer { $true }
            Get-JiraUser -User 'literal opaque identifier'
            Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter { $GetParameter.accountId -eq 'literal opaque identifier' }
        }

        It 'rejects display-name-only objects before making requests' {
            $user = [AtlassianPS.JiraPS.User]@{ DisplayName = 'Human name' }
            { $user | Get-JiraUser } | Should -Throw '*Display names*'
            Should -Invoke Invoke-JiraRequest -Exactly 0
        }

        It 'returns the current-user response without fetching it again' {
            Get-JiraUser
            Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter { $Uri -eq '/rest/api/2/myself' }
        }

        It 'forwards explicit query paging and emits no records for an empty search' {
            Mock Invoke-JiraRequest {}
            @(Get-JiraUser -Query 'name' -IncludeInactive -First 3 -Skip 2 -PageSize 10) | Should -HaveCount 0
            Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter {
                $Uri -eq '/rest/api/2/user/search' -and $GetParameter.username -eq 'name' -and
                $GetParameter.includeInactive -eq 'true' -and $First -eq 3 -and $Skip -eq 2 -and $PageSize -eq 10 -and $Paging
            }
        }

        It 'rejects inactive-user search on Cloud with enumeration guidance' {
            Mock Test-JiraCloudServer { $true }
            { Get-JiraUser -Query 'name' -IncludeInactive } | Should -Throw '*Use -All*'
            Should -Invoke Invoke-JiraRequest -Exactly 0
        }

        It 'uses explicit deployment-specific enumeration endpoints' -ForEach @(
            @{ Cloud = $true; Endpoint = '/rest/api/3/users/search' }
            @{ Cloud = $false; Endpoint = '/rest/api/2/user/list' }
        ) {
            if ($Cloud) { Mock Test-JiraCloudServer { $true } }
            else { Mock Test-JiraCloudServer { $false } }
            Get-JiraUser -All -First 2
            Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter { $Uri -eq $Endpoint -and $Paging }
        }

        It 'explains unsupported Data Center enumeration without adding a version requirement' {
            Mock Invoke-JiraRequest { throw [Management.Automation.ErrorRecord]::new([Exception]::new('missing'), 'NotFound', [Management.Automation.ErrorCategory]::ObjectNotFound, $null) }
            { Get-JiraUser -All } | Should -Throw '*Use -Query*'
        }

        It 'rejects output paging on exact lookup' {
            { Get-JiraUser -User 'name' -First 2 } | Should -Throw '*require -Query or -All*'
            Should -Invoke Invoke-JiraRequest -Exactly 0
        }
    }
}
