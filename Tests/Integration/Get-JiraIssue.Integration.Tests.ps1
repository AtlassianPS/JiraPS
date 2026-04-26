#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

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
        else {
            $script:Skip = $true
        }
    }
}

InModuleScope JiraPS {
    Describe "Get-JiraIssue" -Tag 'Integration', 'Smoke', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            if (-not $env) {
                throw "Initialize-IntegrationEnvironment returned null - tests cannot run"
            }
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
            if (-not $fixtures) {
                throw "Get-TestFixture returned null - tests cannot run"
            }
            if ([string]::IsNullOrEmpty($fixtures.TestIssue)) {
                throw "fixtures.TestIssue is empty - tests should have been skipped"
            }
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Context "Issue Retrieval by Key" {
            It "retrieves an issue by key" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $issue | Should -Not -BeNullOrEmpty
            }

            It "returns the correct issue key" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $issue.Key | Should -Be $fixtures["TestIssue"]
            }

            It "returns the correct type" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $issue.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Issue'
            }

            It "includes the summary" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $issue.Summary | Should -Not -BeNullOrEmpty
            }

            It "includes the project" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $issue.Project | Should -Not -BeNullOrEmpty
                $issue.Project.Key | Should -Be $fixtures["TestProject"]
            }

            It "includes the issue type" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $issue.IssueType | Should -Not -BeNullOrEmpty
            }

            It "includes the status" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $issue.Status | Should -Not -BeNullOrEmpty
            }

            It "includes the description (as string)" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $issue.Description | Should -BeOfType [string]
            }
        }

        Context "Field Selection" {
            It "returns all fields by default" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $issue.Summary | Should -Not -BeNullOrEmpty
                $issue.Status | Should -Not -BeNullOrEmpty
            }

            It "returns only specified fields with -Fields parameter" {
                $issue = Get-JiraIssue -Key $fixtures["TestIssue"] -Fields "summary", "status"
                $issue.Key | Should -Be $fixtures["TestIssue"]
                $issue.Summary | Should -Not -BeNullOrEmpty
            }
        }

        Context "Multiple Issues" {
            It "retrieves multiple issues by key array" {
                $issues = Get-JiraIssue -Key $fixtures["TestIssue"], $fixtures["TestIssue"]
                @($issues).Count | Should -BeGreaterOrEqual 1
            }
        }

        Context "Issue Object Input" {
            It "accepts a AtlassianPS.JiraPS.Issue object via -InputObject" {
                $firstIssue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $refreshed = Get-JiraIssue -InputObject $firstIssue
                $refreshed.Key | Should -Be $fixtures["TestIssue"]
            }

            It "accepts pipeline input" {
                $firstIssue = Get-JiraIssue -Key $fixtures["TestIssue"]
                $refreshed = $firstIssue | Get-JiraIssue
                $refreshed.Key | Should -Be $fixtures["TestIssue"]
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
