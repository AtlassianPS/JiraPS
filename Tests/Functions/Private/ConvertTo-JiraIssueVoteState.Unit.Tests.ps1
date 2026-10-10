#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'ConvertTo-JiraIssueVoteState' -Tag Unit {
        It 'maps wire values and user identities on <deployment>' -TestCases @(
            @{ deployment = 'Cloud'; user = '{"accountId":"user1"}'; identity = 'AccountId' }
            @{ deployment = 'Data Center'; user = '{"name":"user1"}'; identity = 'Name' }
        ) {
            param($user, $identity)
            $wire = ConvertFrom-Json ('{"self":"https://jira.example/votes","votes":0,"hasVoted":false,"voters":[USER]}'.Replace('USER', $user))
            $result = ConvertTo-JiraIssueVoteState $wire
            $result.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueVotes])
            $result.Self | Should -Be ([uri]'https://jira.example/votes')
            $result.Votes | Should -Be 0
            $result.HasVoted | Should -BeFalse
            $result.Voters.GetType() | Should -Be ([AtlassianPS.JiraPS.User[]])
            $result.Voters.Count | Should -Be 1
            $result.Voters[0].$identity | Should -Be 'user1'
        }

        It 'preserves unknown values when fields are omitted' {
            $result = ConvertTo-JiraIssueVoteState (ConvertFrom-Json '{}')
            ($null -eq $result.Votes) | Should -BeTrue
            ($null -eq $result.HasVoted) | Should -BeTrue
            $result.Voters.GetType() | Should -Be ([AtlassianPS.JiraPS.User[]])
            $result.Voters.Count | Should -Be 0
        }

        It 'emits no objects for direct or piped null input' {
            @(ConvertTo-JiraIssueVoteState -InputObject $null).Count | Should -Be 0
            @($null | ConvertTo-JiraIssueVoteState).Count | Should -Be 0
        }

        It 'preserves order and skips null entries (<delivery>)' -TestCases @(
            @{ delivery = 'array' }; @{ delivery = 'pipeline' }
        ) {
            param($delivery)
            $first = [PSCustomObject]@{ votes = 1 }
            $second = [PSCustomObject]@{ votes = 2 }
            $inputs = @($null, $first, $null, $second, $null)
            $results = if ($delivery -eq 'array') {
                @(ConvertTo-JiraIssueVoteState -InputObject $inputs)
            }
            else {
                @($inputs | ConvertTo-JiraIssueVoteState)
            }
            $results.Count | Should -Be 2
            $results[0].Votes | Should -Be 1
            $results[1].Votes | Should -Be 2
        }

        It 'rejects invalid numeric values' {
            $wire = [PSCustomObject]@{ votes = 'invalid' }
            { ConvertTo-JiraIssueVoteState $wire } | Should -Throw
        }
    }
}
