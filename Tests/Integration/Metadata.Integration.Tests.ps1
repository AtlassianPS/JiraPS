#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
}

InModuleScope JiraPS {
    Describe "Metadata" -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Describe "Get-JiraField" {
            Context "Field Retrieval" {
                It "retrieves all fields" {
                    $fields = Get-JiraField

                    $fields | Should -Not -BeNullOrEmpty
                    @($fields).Count | Should -BeGreaterThan 10
                }

                It "returns field objects with correct type" {
                    $fields = Get-JiraField

                    @($fields)[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Field'
                }

                It "includes standard fields" {
                    $fields = Get-JiraField

                    $summaryField = $fields | Where-Object { $_.Id -eq 'summary' }
                    $summaryField | Should -Not -BeNullOrEmpty
                }

                It "includes custom fields" {
                    # Jira Cloud always ships a handful of customfields (Story Points, Epic
                    # Link, Sprint, …) so the assertion holds out-of-the-box. The Server CI
                    # track boots a vanilla AMPS standalone Jira Software image with *no*
                    # custom fields configured by default; skip in that case so this test
                    # stops failing every clean container boot. If/when `Wait-JiraServer.ps1`
                    # starts seeding a customfield (or the test is changed to seed one
                    # itself), drop the skip.
                    $fields = Get-JiraField
                    $customFields = $fields | Where-Object { $_.Id -like 'customfield_*' }
                    if (-not $customFields) {
                        Set-ItResult -Skipped -Because "Deployment has no custom fields configured (default state for the AMPS standalone image)"
                        return
                    }

                    $customFields | Should -Not -BeNullOrEmpty
                }
            }
        }

        Describe "Get-JiraIssueType" {
            Context "Issue Type Retrieval" {
                It "retrieves all issue types" {
                    $types = Get-JiraIssueType

                    $types | Should -Not -BeNullOrEmpty
                }

                It "returns issue type objects with correct type" {
                    $types = Get-JiraIssueType

                    @($types)[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.IssueType'
                }

                It "includes standard issue types" {
                    $types = Get-JiraIssueType

                    $task = $types | Where-Object { $_.Name -eq 'Task' }
                    $task | Should -Not -BeNullOrEmpty
                }

                It "includes issue type ID" {
                    $types = Get-JiraIssueType

                    @($types)[0].Id | Should -Not -BeNullOrEmpty
                }

                It "includes issue type name" {
                    $types = Get-JiraIssueType

                    @($types)[0].Name | Should -Not -BeNullOrEmpty
                }
            }
        }

        Describe "Get-JiraPriority" {
            Context "Priority Retrieval" {
                It "retrieves all priorities" {
                    $priorities = Get-JiraPriority

                    $priorities | Should -Not -BeNullOrEmpty
                }

                It "returns priority objects with correct type" {
                    $priorities = Get-JiraPriority

                    @($priorities)[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Priority'
                }

                It "includes priority ID" {
                    $priorities = Get-JiraPriority

                    @($priorities)[0].Id | Should -Not -BeNullOrEmpty
                }

                It "includes priority name" {
                    $priorities = Get-JiraPriority

                    @($priorities)[0].Name | Should -Not -BeNullOrEmpty
                }
            }
        }

        Describe "Get-JiraStatus" {
            Context "Status Retrieval" {
                BeforeAll {
                    $script:allStatuses = @(Get-JiraStatus)
                }

                It "retrieves all statuses" {
                    $allStatuses | Should -Not -BeNullOrEmpty
                }

                It "returns status objects with correct type" {
                    @($allStatuses)[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Status'
                }

                It "retrieves a status by id" {
                    $target = @($allStatuses)[0]

                    $statusById = @(Get-JiraStatus -Status $target.Id)

                    $statusById | Should -Not -BeNullOrEmpty
                    @($statusById | ForEach-Object { "$($_.Id)" }) | Should -Contain "$($target.Id)"
                }

                It "retrieves a status by name" {
                    $target = @($allStatuses)[0]

                    $statusByName = @(Get-JiraStatus -Status $target.Name)

                    $statusByName | Should -Not -BeNullOrEmpty
                    @($statusByName | ForEach-Object { "$($_.Name)" }) | Should -Contain "$($target.Name)"
                }

                It "supports -IdOrName alias for -Status" {
                    $target = @($allStatuses)[0]

                    $statusByAlias = @(Get-JiraStatus -IdOrName $target.Name)

                    $statusByAlias | Should -Not -BeNullOrEmpty
                    @($statusByAlias | ForEach-Object { "$($_.Name)" }) | Should -Contain "$($target.Name)"
                }
            }
        }

        Describe "Get-JiraIssueLinkType" {
            Context "Link Type Retrieval" {
                It "retrieves all issue link types" {
                    $linkTypes = Get-JiraIssueLinkType

                    $linkTypes | Should -Not -BeNullOrEmpty
                }

                It "returns link type objects with correct type" {
                    $linkTypes = Get-JiraIssueLinkType

                    @($linkTypes)[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.IssueLinkType'
                }

                It "includes inward and outward text" {
                    $linkTypes = Get-JiraIssueLinkType

                    @($linkTypes)[0].InwardText | Should -Not -BeNullOrEmpty
                    @($linkTypes)[0].OutwardText | Should -Not -BeNullOrEmpty
                }
            }
        }

        Describe "Get-JiraIssueCreateMetadata" {
            Context "Create Metadata" {
                It "retrieves create metadata for a project and issue type" {
                    if (-not $fixtures -or [string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    { Get-JiraIssueCreateMetadata -Project $fixtures.TestProject -IssueType 'Task' -ErrorAction Stop } | Should -Not -Throw
                }

                It "returns field metadata" {
                    if (-not $fixtures -or [string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $metadata = Get-JiraIssueCreateMetadata -Project $fixtures.TestProject -IssueType 'Task'

                    if (@($metadata).Count -eq 0) {
                        Set-ItResult -Skipped -Because "Project returns empty create metadata (simplified project)"
                        return
                    }
                    @($metadata).Count | Should -BeGreaterThan 0 -Because "metadata should contain field definitions"
                }
            }
        }

        Describe "Get-JiraIssueEditMetadata" {
            Context "Edit Metadata" {
                It "retrieves edit metadata for an issue" {
                    if (-not $fixtures -or [string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $metadata = Get-JiraIssueEditMetadata -Issue $fixtures.TestIssue

                    $metadata | Should -Not -BeNullOrEmpty
                }

                It "returns field metadata objects" {
                    if (-not $fixtures -or [string]::IsNullOrEmpty($fixtures.TestIssue)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_ISSUE not configured"
                        return
                    }
                    $metadata = Get-JiraIssueEditMetadata -Issue $fixtures.TestIssue

                    @($metadata)[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.EditMetaField'
                }
            }
        }
    }
}
