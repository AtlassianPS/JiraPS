#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

<#
.SYNOPSIS
    Integration test template for JiraPS functions.

.DESCRIPTION
    This template provides the standard structure for integration tests that run
    against a live Jira Cloud instance. Copy this file and rename it to:

        <FunctionName>.Integration.Tests.ps1

    Integration tests verify that functions work correctly with a real Jira API,
    testing actual HTTP requests, responses, and data transformations.

.NOTES
    REQUIREMENTS - All integration tests MUST follow these patterns:

    1. RESOURCE NAMING: Use New-TestResourceName for ALL created resources
       This generates names like "JiraPS-IntTest-Issue-20260419120000" that are:
       - Easily identifiable as test data
       - Unique per test run (timestamp suffix)
       - Discoverable by Remove-StaleTestResource for cleanup

    2. RESOURCE TRACKING: Use ArrayList to track created resources
       - Initialize in outer BeforeAll: $script:createdIssues = [System.Collections.ArrayList]::new()
       - Track in It blocks: $null = $script:createdIssues.Add($issue.Key)
       - Clean up in AfterAll: foreach ($key in $script:createdIssues) { ... }

    3. SCOPE AWARENESS: $script: variables are shared across nested contexts
       The tracking arrays initialized in BeforeAll are accessible from nested
       Context/It blocks because they use $script: scope. This is intentional
       but requires keeping all related tests in the SAME FILE. Do not split
       tests that share cleanup tracking into separate files.

    4. CLEANUP STRATEGY:
       a. Remove-StaleTestResource runs at start to clean up from failed runs
       b. AfterAll cleans up resources created in this specific run
       c. Both use the JiraPS-IntTest- prefix to identify test resources

    5. TAGGING: All Describe blocks MUST include -Tag 'Integration'
       Add -Tag 'Smoke' for tests that should run on every PR

    6. SKIP HANDLING:
       - $script:Skip (from BeforeDiscovery) skips entire Describe when env not configured
       - $script:SkipWrite skips write tests in read-only mode
       These work because BeforeDiscovery runs in file scope before discovery
#>

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
    Describe "FunctionName" -Tag 'Integration' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            #region Setup
            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env

            # IMPORTANT: Initialize tracking arrays BEFORE any tests run
            # These use $script: scope so they're accessible from nested Context/It blocks.
            # WARNING: Do not split tests that add to these arrays into separate files -
            # $script: scope is per-file, so cleanup would fail in split files.
            # Use ArrayList for Add() that doesn't pollute output (returns index)
            $script:createdIssues = [System.Collections.ArrayList]::new()
            $script:createdVersions = [System.Collections.ArrayList]::new()
            $script:createdFilters = [System.Collections.ArrayList]::new()

            # Clean up stale resources from previous failed test runs
            # This ensures tests start with a clean state
            Remove-StaleTestResource -Fixtures $fixtures
            #endregion Setup
        }

        AfterAll {
            #region Cleanup - runs even if tests fail
            # Clean up issues
            if ($script:createdIssues -and $script:createdIssues.Count -gt 0) {
                foreach ($key in $script:createdIssues) {
                    try {
                        Remove-JiraIssue -IssueId $key -Force -ErrorAction SilentlyContinue
                    }
                    catch {
                        Write-Verbose "Cleanup: Failed to remove issue $key - $_"
                    }
                }
            }

            # Clean up versions
            if ($script:createdVersions -and $script:createdVersions.Count -gt 0) {
                foreach ($version in $script:createdVersions) {
                    try {
                        Remove-JiraVersion -Version $version -Force -ErrorAction SilentlyContinue
                    }
                    catch {
                        Write-Verbose "Cleanup: Failed to remove version - $_"
                    }
                }
            }

            # Clean up filters
            if ($script:createdFilters -and $script:createdFilters.Count -gt 0) {
                foreach ($filter in $script:createdFilters) {
                    try {
                        Remove-JiraFilter -InputObject $filter -ErrorAction SilentlyContinue -Confirm:$false
                    }
                    catch {
                        Write-Verbose "Cleanup: Failed to remove filter - $_"
                    }
                }
            }

            Remove-JiraSession -ErrorAction SilentlyContinue
            #endregion Cleanup
        }

        Context "Read Operations" {
            It "performs the expected operation" {
                # Arrange
                $expected = $fixtures.TestIssue

                # Act
                $result = Get-JiraIssue -Key $expected

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.Key | Should -Be $expected
            }
        }

        Context "Return Type Validation" {
            It "returns objects with the correct type name" {
                $result = Get-JiraIssue -Key $fixtures.TestIssue

                $result.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Issue'
            }

            It "returns objects with expected properties" {
                $result = Get-JiraIssue -Key $fixtures.TestIssue

                $result.Key | Should -Not -BeNullOrEmpty
                $result.Summary | Should -Not -BeNullOrEmpty
                $result.Project | Should -Not -BeNullOrEmpty
            }
        }

        Context "Write Operations" -Skip:$SkipWrite {
            It "creates a new resource" {
                # Use prefixed name for cleanup discoverability
                $summary = New-TestResourceName -Type "Issue"

                $issue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                # Track for cleanup - Add() returns index, use $null to suppress
                $null = $script:createdIssues.Add($issue.Key)

                $issue | Should -Not -BeNullOrEmpty
                $issue.Key | Should -Match "^$($fixtures.TestProject)-\d+$"
            }

            It "updates an existing resource" {
                $summary = New-TestResourceName -Type "UpdateTest"
                $issue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                $null = $script:createdIssues.Add($issue.Key)

                $newSummary = New-TestResourceName -Type "Updated"
                Set-JiraIssue -Issue $issue.Key -Summary $newSummary

                $updated = Get-JiraIssue -Key $issue.Key
                $updated.Summary | Should -Be $newSummary
            }
        }

        Context "Error Handling" {
            It "throws appropriate error for non-existent resource" {
                { Get-JiraIssue -Key "NONEXISTENT-99999" -ErrorAction Stop } |
                    Should -Throw
            }
        }
    }
}
