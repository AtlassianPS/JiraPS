#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraIssueProgress" -Tag 'Unit' {
        It 'maps wire values to typed properties' {
            $wire = ConvertFrom-Json -InputObject @'
{
    "progress": 0,
    "total": 2147483648,
    "percent": 0
}
'@
            $result = ConvertTo-JiraIssueProgress -InputObject $wire
            $result.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueProgress])
            $result.Progress | Should -Be 0
            $result.Total | Should -Be 2147483648
            $result.Percent | Should -Be 0
        }

        It 'preserves unknown values when fields are omitted' {
            $result = ConvertTo-JiraIssueProgress -InputObject (ConvertFrom-Json '{}')
            ($null -eq $result.Progress) | Should -BeTrue
            ($null -eq $result.Total) | Should -BeTrue
            ($null -eq $result.Percent) | Should -BeTrue
        }

        It 'emits no objects for direct or piped null input' {
            @(ConvertTo-JiraIssueProgress -InputObject $null).Count | Should -Be 0
            @($null | ConvertTo-JiraIssueProgress).Count | Should -Be 0
        }

        It 'preserves order and skips null entries (<delivery>)' -TestCases @(
            @{ delivery = 'array' }
            @{ delivery = 'pipeline' }
        ) {
            param($delivery)
            $first = [PSCustomObject]@{ progress = 1 }
            $second = [PSCustomObject]@{ progress = 2 }
            $inputs = @($null, $first, $null, $second, $null)
            $results = if ($delivery -eq 'array') { @(ConvertTo-JiraIssueProgress -InputObject $inputs) }
            else { @($inputs | ConvertTo-JiraIssueProgress) }
            $results.Count | Should -Be 2
            $results[0].Progress | Should -Be 1
            $results[1].Progress | Should -Be 2
        }

        It 'rejects invalid numeric values' {
            $wire = [PSCustomObject]@{ progress = 'invalid' }
            { ConvertTo-JiraIssueProgress -InputObject $wire } | Should -Throw -ExpectedMessage '*Cannot convert value "invalid" to type "System.Int64"*'
        }
    }
}
