#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Integration tests require plaintext credential conversion for API tokens')]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    $script:SkipNormal = Skip-IntegrationTestForNormalUser
}

InModuleScope JiraPS {
    Describe "Permissions" -Tag 'Integration' -Skip:$SkipNormal {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            #region Setup
            $script:env = Initialize-IntegrationEnvironment
            $script:fixtures = Get-TestFixture -Environment $env

            # Track resources created by the admin session so AfterAll can sweep them up.
            $script:createdIssues = [System.Collections.ArrayList]::new()
            $script:createdFilters = [System.Collections.ArrayList]::new()

            # Helpers to switch between the admin and normal-user sessions inside an It block.
            # Kept local to this file because they only make sense for permission-boundary tests
            # and would be scope creep in IntegrationTestTools.ps1.
            function Use-AdminSession {
                Remove-JiraSession -ErrorAction SilentlyContinue
                Connect-JiraTestServer -Environment $script:env | Out-Null
            }

            function Use-NormalSession {
                Remove-JiraSession -ErrorAction SilentlyContinue
                Connect-JiraTestServerAsNormalUser -Environment $script:env | Out-Null
            }

            # Establish the admin session first so Remove-StaleTestResource has a chance to run
            # via Connect-JiraTestServer's built-in sweep before any normal-user tests start.
            Use-AdminSession
            #endregion Setup
        }

        AfterAll {
            #region Cleanup - runs even if tests fail
            # Cleanup deletes resources, so it must run as the admin user. The normal user
            # will typically lack the permissions needed to remove the test artifacts.
            try {
                Remove-JiraSession -ErrorAction SilentlyContinue
                Connect-JiraTestServer -Environment $script:env | Out-Null
            }
            catch {
                Write-Verbose "Cleanup: Failed to re-establish admin session - $_"
            }

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

        Context "Normal-user authentication" {
            It "lists projects when authenticated as the normal user" {
                # Arrange
                Use-NormalSession

                # Act
                $projects = Get-JiraProject

                # Assert
                $projects | Should -Not -BeNullOrEmpty -Because "the normal user should have access to at least the test project"
                @($projects).Where({ $_.Key -eq $fixtures.TestProject }) |
                    Should -Not -BeNullOrEmpty -Because "the normal user should be able to see the configured test project '$($fixtures.TestProject)'"
            }
        }

        Context "Normal-user can read but not delete an admin-owned filter" {
            It "lets the normal user retrieve an admin-created filter, but blocks deletion" {
                # Arrange - admin creates a filter
                Use-AdminSession
                $filterName = New-TestResourceName -Type 'Filter'
                $jql = "project = $($fixtures.TestProject)"
                $adminFilter = New-JiraFilter -Name $filterName -JQL $jql
                $null = $script:createdFilters.Add($adminFilter)

                # Act + Assert (read) - normal user can fetch the filter by ID
                Use-NormalSession
                $fetched = Get-JiraFilter -Id $adminFilter.Id
                $fetched | Should -Not -BeNullOrEmpty
                $fetched.Id | Should -Be $adminFilter.Id

                # Act + Assert (write) - normal user is blocked from deleting it
                { Remove-JiraFilter -InputObject $adminFilter -ErrorAction Stop -Confirm:$false } |
                    Should -Throw -Because "the normal user is not the filter owner and is not a Jira administrator"
            }
        }

        Context "Normal-user cannot delete an admin-owned issue" {
            It "throws when the normal user tries to remove an admin-created issue" {
                # Arrange - admin creates an issue
                Use-AdminSession
                $summary = New-TestResourceName -Type 'PermIssue'
                $issue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                $null = $script:createdIssues.Add($issue.Key)

                # Act + Assert - normal user is blocked from deleting it
                Use-NormalSession
                { Remove-JiraIssue -IssueId $issue.Key -Force -ErrorAction Stop } |
                    Should -Throw -Because "the normal user lacks the Delete Issue permission on the test project"

                # Sanity check - the issue still exists when fetched as admin
                Use-AdminSession
                $stillThere = Get-JiraIssue -Key $issue.Key
                $stillThere | Should -Not -BeNullOrEmpty
                $stillThere.Key | Should -Be $issue.Key
            }
        }
    }
}
