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
    Describe "Filters" -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
            $script:createdFilters = [System.Collections.ArrayList]::new()

            # Seed one saved filter for the read-only `Find-JiraFilter` tests below.
            # Reasoning:
            #   - `Find-JiraFilter -Name "test"` and `Find-JiraFilter` ("my filters")
            #     both used to assume the authenticated account had at least one
            #     pre-existing filter. That holds for the long-lived Cloud test
            #     account but breaks the moment we boot a fresh Data Center
            #     container, where the admin account starts with zero filters.
            #   - The seeded filter's name uses `New-TestResourceName -Type "Filter"`
            #     so it carries the `JiraPS-IntTest-` prefix. That prefix contains
            #     the substring "Test", which makes `Find-JiraFilter -Name "test"`
            #     match it (Jira's filter search is a case-insensitive substring
            #     match on the filter name) and also lets `Remove-StaleTestResource`
            #     reap it on subsequent runs if AfterAll ever fails to clean up.
            #   - We skip the seed in read-only mode (e.g. `JIRA_TEST_READONLY=true`
            #     against a production-like Cloud account); the dependent tests
            #     self-skip via `$script:SeededFilter` below.
            $script:SeededFilter = $null
            if (-not $env.ReadOnly -and -not [string]::IsNullOrEmpty($fixtures.TestProject)) {
                try {
                    $script:SeededFilter = New-JiraFilter `
                        -Name (New-TestResourceName -Type "Filter") `
                        -JQL "project = $($fixtures.TestProject)" `
                        -Description "Auto-seeded by Filters.Integration.Tests.ps1 so Find-JiraFilter has data on a fresh deployment. Safe to delete."
                    if ($script:SeededFilter) {
                        $null = $script:createdFilters.Add($script:SeededFilter)
                    }
                }
                catch {
                    Write-Warning "Filters integration tests: failed to seed a baseline filter ($($_.Exception.Message)). Find-JiraFilter assertions will self-skip."
                }
            }
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
                    if (-not $script:SeededFilter) {
                        Set-ItResult -Skipped -Because "Could not seed a baseline filter (read-only mode or missing TestProject); see BeforeAll warning."
                        return
                    }
                    # The seeded filter name carries the JiraPS-IntTest- prefix, so
                    # searching for "test" finds it via case-insensitive substring
                    # match (the prefix contains "Test").
                    $filters = Find-JiraFilter -Name "test"

                    $filters | Should -Not -BeNullOrEmpty -Because "the BeforeAll seeded a filter whose name contains 'Test'"
                    @($filters)[0] | Should -BeOfType [PSCustomObject]
                }

                It "retrieves my filters" {
                    if (-not $script:SeededFilter) {
                        Set-ItResult -Skipped -Because "Could not seed a baseline filter (read-only mode or missing TestProject); see BeforeAll warning."
                        return
                    }
                    # `Find-JiraFilter` (no args) returns filters owned by the
                    # authenticated user. The seeded filter was created in this
                    # session, so the account is guaranteed to own at least one.
                    $filters = Find-JiraFilter

                    $filters | Should -Not -BeNullOrEmpty -Because "the seeded filter is owned by the test account"
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
