#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'ConvertTo-JiraIssueWatchState' -Tag Unit {
        It 'maps wire values and user identities on <deployment>' -TestCases @(
            @{ deployment = 'Cloud'; user = '{"accountId":"user1"}'; identity = 'AccountId' }
            @{ deployment = 'Data Center'; user = '{"name":"user1"}'; identity = 'Name' }
        ) {
            param($user, $identity)
            $wire = ConvertFrom-Json ('{"self":"https://jira.example/watchers","watchCount":0,"isWatching":false,"watchers":[USER]}'.Replace('USER', $user))
            $result = ConvertTo-JiraIssueWatchState $wire
            $result.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueWatches])
            $result.Self | Should -Be ([uri]'https://jira.example/watchers')
            $result.WatchCount | Should -Be 0
            $result.IsWatching | Should -BeFalse
            $result.Watchers.GetType() | Should -Be ([AtlassianPS.JiraPS.User[]])
            $result.Watchers.Count | Should -Be 1
            $result.Watchers[0].$identity | Should -Be 'user1'
        }

        It 'preserves unknown values when fields are omitted' {
            $result = ConvertTo-JiraIssueWatchState (ConvertFrom-Json '{}')
            ($null -eq $result.WatchCount) | Should -BeTrue
            ($null -eq $result.IsWatching) | Should -BeTrue
            $result.Watchers.GetType() | Should -Be ([AtlassianPS.JiraPS.User[]])
            $result.Watchers.Count | Should -Be 0
        }

        It 'emits no objects for direct or piped null input' {
            @(ConvertTo-JiraIssueWatchState -InputObject $null).Count | Should -Be 0
            @($null | ConvertTo-JiraIssueWatchState).Count | Should -Be 0
        }

        It 'preserves order and skips null entries (<delivery>)' -TestCases @(
            @{ delivery = 'array' }; @{ delivery = 'pipeline' }
        ) {
            param($delivery)
            $first = [PSCustomObject]@{ watchCount = 1 }
            $second = [PSCustomObject]@{ watchCount = 2 }
            $inputs = @($null, $first, $null, $second, $null)
            $results = if ($delivery -eq 'array') {
                @(ConvertTo-JiraIssueWatchState -InputObject $inputs)
            }
            else {
                @($inputs | ConvertTo-JiraIssueWatchState)
            }
            $results.Count | Should -Be 2
            $results[0].WatchCount | Should -Be 1
            $results[1].WatchCount | Should -Be 2
        }

        It 'rejects invalid numeric values' {
            $wire = [PSCustomObject]@{ watchCount = 'invalid' }
            { ConvertTo-JiraIssueWatchState $wire } | Should -Throw
        }
    }
}
