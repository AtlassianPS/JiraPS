#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    $script:TestIssueKey = $null
    $script:TestProjectKey = $null

    if (-not $Skip) {
        $testEnv = Initialize-IntegrationEnvironment
        if ($testEnv -and -not [string]::IsNullOrEmpty($testEnv.TestIssue)) {
            $script:TestIssueKey = $testEnv.TestIssue
            $script:TestProjectKey = $testEnv.TestProject
        }
        else { $script:Skip = $true }
    }
}

InModuleScope JiraPS {
    Describe "Get-JiraIssue" -Tag 'Integration', 'Smoke', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            if (-not $env) { throw "Initialize-IntegrationEnvironment returned null - tests cannot run" }
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
            if (-not $fixtures) { throw "Get-TestFixture returned null - tests cannot run" }
            if ([string]::IsNullOrEmpty($fixtures.TestIssue)) { throw "fixtures.TestIssue is empty - tests should have been skipped" }
        }

        AfterAll {
            Disconnect-Jira -ErrorAction SilentlyContinue
        }

        Context "Issue Retrieval by Key" {
            It 'retrieves the requested typed issue with its default fields' {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"] -ErrorAction Stop

                $issue | Should -BeOfType ([AtlassianPS.JiraPS.Issue])
                $issue.Key | Should -Be $fixtures["TestIssue"]
                $issue.Summary | Should -Not -BeNullOrEmpty
                $issue.Project.Key | Should -Be $fixtures["TestProject"]
                $issue.IssueType | Should -Not -BeNullOrEmpty
                $issue.Status | Should -Not -BeNullOrEmpty
                $issue.Description | Should -BeOfType [string]
            }
        }

        Context "Field Selection" {

            It "returns only specified fields with -Fields parameter" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"] -Fields "summary", "status"
                $issue.Key | Should -Be $fixtures["TestIssue"]
                $issue.Summary | Should -Not -BeNullOrEmpty
                $issue.Status | Should -Not -BeNullOrEmpty
                $issue.Project | Should -BeNullOrEmpty
            }
        }

        Context "Issue Object Input" {
            It "accepts a AtlassianPS.JiraPS.Issue object via -InputObject" {
                $firstIssue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $refreshed = Get-JiraIssue -Issue $firstIssue
                $refreshed.Key | Should -Be $fixtures["TestIssue"]
            }

            It "accepts pipeline input" {
                $firstIssue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $refreshed = $firstIssue | Get-JiraIssue
                $refreshed.Key | Should -Be $fixtures["TestIssue"]
            }
        }

        Context "History Expansion" {
            It "adds History when -IncludeHistory is used with -Key" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"] -IncludeHistory

                $issue | Should -Not -BeNullOrEmpty
                $issue.PSObject.Properties.Name | Should -Contain 'History'
                $issue.History.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueHistoryEntry[]])
            }

            It "supports the -GetHistory alias" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"] -GetHistory

                $issue | Should -Not -BeNullOrEmpty
                $issue.PSObject.Properties.Name | Should -Contain 'History'
                $issue.History.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueHistoryEntry[]])
            }

            It "adds History when -IncludeHistory is used with -Query" {
                $jql = "key = $($fixtures.TestIssue)"

                $issues = Get-JiraIssue -Query $jql -IncludeHistory

                @($issues).Count | Should -BeGreaterThan 0
                @($issues)[0].PSObject.Properties.Name | Should -Contain 'History'
                @($issues)[0].History.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueHistoryEntry[]])
            }
        }

        Context "Error Handling" {
            It "throws for non-existent issue" {
                {
                    Get-JiraIssue -Key "NONEXISTENT-99999" -ErrorAction Stop
                } | Should -Throw
            }

            It "throws for issue key that doesn't exist on server" {
                { Get-JiraIssue -Key "invalid" -ErrorAction Stop } | Should -Throw
            }
        }
    }
}
