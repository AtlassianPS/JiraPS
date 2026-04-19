#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $testEnv = Initialize-IntegrationEnvironment
        $script:SkipWrite = $testEnv.ReadOnly
    }
}

InModuleScope JiraPS {
    Describe "Remove-JiraIssue" -Tag 'Integration' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Context "Delete Operations" -Skip:$SkipWrite {
            It "deletes an issue by key" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $summary = New-TestResourceName -Type "DeleteKey"
                $issue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary

                { Remove-JiraIssue -IssueId $issue.Key -Force } | Should -Not -Throw

                { Get-JiraIssue -Key $issue.Key -ErrorAction Stop } | Should -Throw
            }

            It "deletes an issue via pipeline" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $summary = New-TestResourceName -Type "DeletePipe"
                $issue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary

                { $issue | Remove-JiraIssue -Force } | Should -Not -Throw

                { Get-JiraIssue -Key $issue.Key -ErrorAction Stop } | Should -Throw
            }

            It "deletes an issue object" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $summary = New-TestResourceName -Type "DeleteObj"
                $issue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary

                { Remove-JiraIssue -Issue $issue -Force } | Should -Not -Throw

                { Get-JiraIssue -Key $issue.Key -ErrorAction Stop } | Should -Throw
            }
        }

        Context "Error Handling" -Skip:$SkipWrite {
            It "fails for non-existent issue" {
                { Remove-JiraIssue -IssueId 'NONEXISTENT-99999' -Force -ErrorAction Stop } |
                    Should -Throw
            }
        }
    }
}
