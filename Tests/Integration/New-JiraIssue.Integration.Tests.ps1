#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $testEnv = Initialize-IntegrationEnvironment
        $script:SkipWrite = $testEnv.ReadOnly
    }
}

InModuleScope JiraPS {
    Describe "New-JiraIssue" -Tag 'Integration', 'Smoke', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env

            # Initialize tracking array BEFORE any tests run
            $script:createdIssues = [System.Collections.ArrayList]::new()

            # Clean up stale resources from previous failed runs
            Remove-StaleTestResource -Fixtures $fixtures
        }

        AfterAll {
            # Cleanup is resilient - handles null/empty arrays gracefully
            if ($script:createdIssues -and $script:createdIssues.Count -gt 0) {
                foreach ($issueKey in $script:createdIssues) {
                    try {
                        Remove-JiraIssue -IssueId $issueKey -Force -ErrorAction SilentlyContinue
                        Write-Verbose "Cleaned up test issue: $issueKey"
                    }
                    catch {
                        Write-Warning "Failed to clean up issue $issueKey : $_"
                    }
                }
            }
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Context "Basic Issue Creation" -Skip:$SkipWrite {
            # `Get-MinimumValidIssueParameter` adapts the create payload to the
            # project's actual field configuration: a no-op against the Cloud
            # Task project, but on the Server track's `jira-core-task-management`
            # template it auto-supplies tightened `required: true,
            # hasDefaultValue: false` fields (Reporter on the moveworkforward
            # AMPS image, sometimes Priority). Without it these tests can fail
            # with real Jira validation errors on deployments whose field
            # configuration tightens create requirements beyond the Cloud
            # baseline payload.
            It "creates a new issue with required fields" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $summary = New-TestResourceName -Type "Issue"
                $extras = Get-MinimumValidIssueParameter -Fixtures $fixtures
                $params = @{ Project = $fixtures.TestProject; IssueType = 'Task'; Summary = $summary }
                if ($extras.Reporter) { $params.Reporter = $extras.Reporter }
                if ($extras.Fields -and $extras.Fields.Count -gt 0) { $params.Fields = $extras.Fields }

                $issue = New-JiraIssue @params
                $null = $script:createdIssues.Add($issue.Key)

                $issue | Should -Not -BeNullOrEmpty
                $issue.Key | Should -Match "^$($fixtures.TestProject)-\d+$"
                $issue.Summary | Should -Be $summary
            }

            It "creates an issue with description" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $summary = New-TestResourceName -Type "IssueDesc"
                $description = "This is a test description created by JiraPS integration tests."
                $extras = Get-MinimumValidIssueParameter -Fixtures $fixtures -SkipFieldId @('description')
                $params = @{ Project = $fixtures.TestProject; IssueType = 'Task'; Summary = $summary; Description = $description }
                if ($extras.Reporter) { $params.Reporter = $extras.Reporter }
                if ($extras.Fields -and $extras.Fields.Count -gt 0) { $params.Fields = $extras.Fields }

                $issue = New-JiraIssue @params
                $null = $script:createdIssues.Add($issue.Key)

                $issue | Should -Not -BeNullOrEmpty
                $issue.Description | Should -Not -BeNullOrEmpty
            }

            It "returns an issue with correct type" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $summary = New-TestResourceName -Type "IssueType"
                $extras = Get-MinimumValidIssueParameter -Fixtures $fixtures
                $params = @{ Project = $fixtures.TestProject; IssueType = 'Task'; Summary = $summary }
                if ($extras.Reporter) { $params.Reporter = $extras.Reporter }
                if ($extras.Fields -and $extras.Fields.Count -gt 0) { $params.Fields = $extras.Fields }

                $issue = New-JiraIssue @params
                $null = $script:createdIssues.Add($issue.Key)

                $issue.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Issue'
            }
        }

        Context "Issue Types" -Skip:$SkipWrite {
            It "creates a Task" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $summary = New-TestResourceName -Type "Task"
                $extras = Get-MinimumValidIssueParameter -Fixtures $fixtures
                $params = @{ Project = $fixtures.TestProject; IssueType = 'Task'; Summary = $summary }
                if ($extras.Reporter) { $params.Reporter = $extras.Reporter }
                if ($extras.Fields -and $extras.Fields.Count -gt 0) { $params.Fields = $extras.Fields }

                $issue = New-JiraIssue @params
                $null = $script:createdIssues.Add($issue.Key)

                $issue.IssueType.Name | Should -Be 'Task'
            }
        }

        Context "Custom Fields" -Skip:$SkipWrite {
            It "accepts additional fields via -Fields parameter" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                $summary = New-TestResourceName -Type "Fields"
                $fields = @{
                    description = "Description set via Fields parameter"
                }
                $extras = Get-MinimumValidIssueParameter -Fixtures $fixtures -SkipFieldId @('description')
                if ($extras.Fields) {
                    foreach ($k in $extras.Fields.Keys) { $fields[$k] = $extras.Fields[$k] }
                }
                $params = @{ Project = $fixtures.TestProject; IssueType = 'Task'; Summary = $summary; Fields = $fields }
                if ($extras.Reporter) { $params.Reporter = $extras.Reporter }

                $issue = New-JiraIssue @params
                $null = $script:createdIssues.Add($issue.Key)

                $issue | Should -Not -BeNullOrEmpty
            }
        }

        Context "Error Handling" -Skip:$SkipWrite {
            It "fails for non-existent project" {
                { New-JiraIssue -Project 'NONEXISTENT' -IssueType 'Task' -Summary 'Test' -ErrorAction Stop } |
                    Should -Throw
            }

            It "fails for invalid issue type" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                { New-JiraIssue -Project $fixtures.TestProject -IssueType 'InvalidType' -Summary 'Test' -ErrorAction Stop } |
                    Should -Throw
            }

            It "fails without required summary" {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                    return
                }
                { New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary '' -ErrorAction Stop } |
                    Should -Throw
            }
        }
    }
}
