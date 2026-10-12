#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraIssueVote" -Tag 'Unit' {
        It 'maps wire values and user identities on <deployment>' -TestCases @(
            @{
                deployment = 'Cloud'
                identity   = 'accountId'
            }
            @{
                deployment = 'Data Center'
                identity   = 'name'
            }
        ) {
            param($identity)
            $wire = [PSCustomObject]@{
                self     = 'https://jira.example/votes'
                votes    = 0
                hasVoted = $false
                voters   = @([PSCustomObject]@{ $identity = 'user1' })
            } | ConvertTo-Json -Depth 5 | ConvertFrom-Json
            $result = ConvertTo-JiraIssueVote -InputObject $wire
            $result.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueVotes])
            $result.Self | Should -Be ([uri]'https://jira.example/votes')
            $result.Votes | Should -Be 0
            $result.HasVoted | Should -BeFalse
            $result.Voters.GetType() | Should -Be ([AtlassianPS.JiraPS.User[]])
            $result.Voters.Count | Should -Be 1
            $result.Voters[0].$identity | Should -Be 'user1'
        }

        It 'preserves unknown values when fields are omitted' {
            $result = ConvertTo-JiraIssueVote -InputObject (ConvertFrom-Json '{}')
            ($null -eq $result.Votes) | Should -BeTrue
            ($null -eq $result.HasVoted) | Should -BeTrue
            $result.Voters.GetType() | Should -Be ([AtlassianPS.JiraPS.User[]])
            $result.Voters.Count | Should -Be 0
        }

        It 'preserves order and skips null entries (<delivery>)' -TestCases @(
            @{ delivery = 'array' }
            @{ delivery = 'pipeline' }
        ) {
            param($delivery)
            $first = [PSCustomObject]@{ votes = 1 }
            $second = [PSCustomObject]@{ votes = 2 }
            $inputs = @($null, $first, $null, $second, $null)
            $results = if ($delivery -eq 'array') { @(ConvertTo-JiraIssueVote -InputObject $inputs) }
            else { @($inputs | ConvertTo-JiraIssueVote) }
            $results.Count | Should -Be 2
            $results[0].Votes | Should -Be 1
            $results[1].Votes | Should -Be 2
        }

        It 'rejects invalid numeric values' {
            $wire = [PSCustomObject]@{ votes = 'invalid' }
            { ConvertTo-JiraIssueVote -InputObject $wire } | Should -Throw -ExpectedMessage '*Cannot convert value "invalid" to type "System.Int64"*'
        }
    }
}
