#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraIssueTimeTracking" -Tag 'Unit' {
        It 'maps wire values to typed properties' {
            $wire = ConvertFrom-Json -InputObject @'
{
    "originalEstimate": "2h",
    "remainingEstimate": "1h",
    "timeSpent": "0m",
    "originalEstimateSeconds": 7200,
    "remainingEstimateSeconds": 3600,
    "timeSpentSeconds": 0
}
'@
            $result = ConvertTo-JiraIssueTimeTracking -InputObject $wire
            $result.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueTimeTracking])
            $result.OriginalEstimate | Should -Be '2h'
            $result.RemainingEstimate | Should -Be '1h'
            $result.TimeSpent | Should -Be '0m'
            $result.OriginalEstimateSeconds | Should -Be 7200
            $result.RemainingEstimateSeconds | Should -Be 3600
            $result.TimeSpentSeconds | Should -Be 0
        }

        It 'preserves unknown values when fields are omitted' {
            $result = ConvertTo-JiraIssueTimeTracking -InputObject (ConvertFrom-Json '{}')
            ($null -eq $result.OriginalEstimateSeconds) | Should -BeTrue
            ($null -eq $result.RemainingEstimateSeconds) | Should -BeTrue
            ($null -eq $result.TimeSpentSeconds) | Should -BeTrue
        }

        It 'preserves order and skips null entries (<delivery>)' -TestCases @(
            @{ delivery = 'array' }
            @{ delivery = 'pipeline' }
        ) {
            param($delivery)
            $first = [PSCustomObject]@{ timeSpentSeconds = 1 }
            $second = [PSCustomObject]@{ timeSpentSeconds = 2 }
            $inputs = @($null, $first, $null, $second, $null)
            $results = if ($delivery -eq 'array') { @(ConvertTo-JiraIssueTimeTracking -InputObject $inputs) }
            else { @($inputs | ConvertTo-JiraIssueTimeTracking) }
            $results.Count | Should -Be 2
            $results[0].TimeSpentSeconds | Should -Be 1
            $results[1].TimeSpentSeconds | Should -Be 2
        }

        It 'rejects invalid numeric values' {
            $wire = [PSCustomObject]@{ timeSpentSeconds = 'invalid' }
            { ConvertTo-JiraIssueTimeTracking -InputObject $wire } | Should -Throw -ExpectedMessage '*Cannot convert value "invalid" to type "System.Int64"*'
        }
    }
}
