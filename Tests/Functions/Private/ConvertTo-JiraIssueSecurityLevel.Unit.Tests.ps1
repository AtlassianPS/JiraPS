#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraIssueSecurityLevel" -Tag 'Unit' {
        It 'maps wire values to typed properties' {
            $wire = ConvertFrom-Json -InputObject @'
{
    "id": "5",
    "name": "Internal",
    "description": "Restricted access",
    "self": "https://jira.example/security/5"
}
'@
            $result = ConvertTo-JiraIssueSecurityLevel -InputObject $wire
            $result.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueSecurityLevel])
            $result.Id | Should -Be '5'
            $result.Name | Should -Be 'Internal'
            $result.Description | Should -Be 'Restricted access'
            $result.Self | Should -Be ([uri]'https://jira.example/security/5')
        }

        It 'preserves unknown values when fields are omitted' {
            $result = ConvertTo-JiraIssueSecurityLevel -InputObject (ConvertFrom-Json '{}')
            $result.Id | Should -BeNullOrEmpty
            $result.Name | Should -BeNullOrEmpty
            $result.Description | Should -BeNullOrEmpty
            ($null -eq $result.Self) | Should -BeTrue
        }

        It 'emits no objects for direct or piped null input' {
            @(ConvertTo-JiraIssueSecurityLevel -InputObject $null).Count | Should -Be 0
            @($null | ConvertTo-JiraIssueSecurityLevel).Count | Should -Be 0
        }

        It 'preserves order and skips null entries (<delivery>)' -TestCases @(
            @{ delivery = 'array' }
            @{ delivery = 'pipeline' }
        ) {
            param($delivery)
            $first = [PSCustomObject]@{ id = 1 }
            $second = [PSCustomObject]@{ id = 2 }
            $inputs = @($null, $first, $null, $second, $null)
            $results = if ($delivery -eq 'array') {
                @(ConvertTo-JiraIssueSecurityLevel -InputObject $inputs)
            }
            else {
                @($inputs | ConvertTo-JiraIssueSecurityLevel)
            }
            $results.Count | Should -Be 2
            $results[0].Id | Should -Be 1
            $results[1].Id | Should -Be 2
        }
    }
}
