#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $testEnv = Initialize-IntegrationEnvironment
        $script:SkipWrite = $testEnv.ReadOnly
        $script:SkipFilterTests = [string]::IsNullOrEmpty($testEnv.TestFilter)
    }
}

InModuleScope JiraPS {
    Describe "Filters" -Tag 'Integration' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
            $script:createdFilters = [System.Collections.ArrayList]::new()
        }

        AfterAll {
            foreach ($filter in $createdFilters) {
                Remove-JiraFilter -InputObject $filter -ErrorAction SilentlyContinue -Confirm:$false
            }
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Describe "Get-JiraFilter" {
            Context "Filter Retrieval" {
                It "retrieves a filter by ID" {
                    if ([string]::IsNullOrEmpty($fixtures.TestFilter)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_FILTER not configured"
                        return
                    }
                    $filter = Get-JiraFilter -Id $fixtures.TestFilter

                    $filter | Should -Not -BeNullOrEmpty
                }

                It "returns filter object with correct type" {
                    if ([string]::IsNullOrEmpty($fixtures.TestFilter)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_FILTER not configured"
                        return
                    }
                    $filter = Get-JiraFilter -Id $fixtures.TestFilter

                    $filter.PSObject.TypeNames[0] | Should -Be 'JiraPS.Filter'
                }

                It "includes filter name" {
                    if ([string]::IsNullOrEmpty($fixtures.TestFilter)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_FILTER not configured"
                        return
                    }
                    $filter = Get-JiraFilter -Id $fixtures.TestFilter

                    $filter.Name | Should -Not -BeNullOrEmpty
                }

                It "includes JQL query" {
                    if ([string]::IsNullOrEmpty($fixtures.TestFilter)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_FILTER not configured"
                        return
                    }
                    $filter = Get-JiraFilter -Id $fixtures.TestFilter

                    $filter.JQL | Should -Not -BeNullOrEmpty
                }
            }
        }

        Describe "Find-JiraFilter" {
            Context "Filter Search" {
                It "searches for filters by name" {
                    $filters = Find-JiraFilter -Name "test"

                    $filters | Should -BeOfType [PSCustomObject]
                }

                It "retrieves my filters" {
                    $filters = Find-JiraFilter

                    # The test account should have at least one filter
                    $filters | Should -Not -BeNullOrEmpty -Because "test account should have at least one filter"
                    @($filters)[0] | Should -BeOfType [PSCustomObject]
                }
            }
        }

        Describe "New-JiraFilter" -Skip:$SkipWrite {
            Context "Filter Creation" {
                It "creates a new filter" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $filterName = New-TestResourceName -Type "Filter"
                    $jql = "project = $($fixtures.TestProject)"

                    $filter = New-JiraFilter -Name $filterName -JQL $jql
                    $null = $script:createdFilters.Add($filter)

                    $filter | Should -Not -BeNullOrEmpty
                    $filter.Name | Should -Be $filterName
                    $filter.JQL | Should -Be $jql
                }

                It "creates a filter with description" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $filterName = New-TestResourceName -Type "FilterDesc"
                    $jql = "project = $($fixtures.TestProject)"

                    $filter = New-JiraFilter -Name $filterName -JQL $jql -Description "Test filter"
                    $null = $script:createdFilters.Add($filter)

                    $filter.Description | Should -Be "Test filter"
                }

                It "returns filter object with correct type" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $filterName = New-TestResourceName -Type "FilterType"
                    $jql = "project = $($fixtures.TestProject)"

                    $filter = New-JiraFilter -Name $filterName -JQL $jql
                    $null = $script:createdFilters.Add($filter)

                    $filter.PSObject.TypeNames[0] | Should -Be 'JiraPS.Filter'
                }
            }
        }

        Describe "Set-JiraFilter" -Skip:$SkipWrite {
            BeforeAll {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    $script:testFilter = $null
                }
                else {
                    $filterName = New-TestResourceName -Type "FilterSet"
                    $script:testFilter = New-JiraFilter -Name $filterName -JQL "project = $($fixtures.TestProject)"
                    $null = $script:createdFilters.Add($testFilter)
                }
            }

            Context "Filter Updates" {
                It "updates filter name" {
                    if (-not $testFilter) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $newName = New-TestResourceName -Type "FilterUpdated"

                    Set-JiraFilter -InputObject $testFilter -Name $newName

                    $updated = Get-JiraFilter -Id $testFilter.Id
                    $updated.Name | Should -Be $newName
                }

                It "updates filter description" {
                    if (-not $testFilter) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $newDescription = "Updated at $(Get-Date)"

                    Set-JiraFilter -InputObject $testFilter -Description $newDescription

                    $updated = Get-JiraFilter -Id $testFilter.Id
                    $updated.Description | Should -Be $newDescription
                }

                It "updates filter JQL" {
                    if (-not $testFilter) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $newJql = "project = $($fixtures.TestProject) ORDER BY created DESC"

                    Set-JiraFilter -InputObject $testFilter -JQL $newJql

                    $updated = Get-JiraFilter -Id $testFilter.Id
                    $updated.JQL | Should -Be $newJql
                }
            }
        }

        Describe "Remove-JiraFilter" -Skip:$SkipWrite {
            Context "Filter Deletion" {
                It "deletes a filter" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }
                    $filterName = New-TestResourceName -Type "FilterDelete"
                    $filter = New-JiraFilter -Name $filterName -JQL "project = $($fixtures.TestProject)"

                    { Remove-JiraFilter -InputObject $filter -Confirm:$false } | Should -Not -Throw

                    { Get-JiraFilter -Id $filter.Id -ErrorAction Stop } | Should -Throw
                }
            }
        }
    }
}
