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
            #   - `Find-JiraFilter -Name <seeded-name>` and `Find-JiraFilter`
            #     ("my filters")
            #     both used to assume the authenticated account had at least one
            #     pre-existing filter. That holds for the long-lived Cloud test
            #     account but breaks the moment we boot a fresh Data Center
            #     container, where the admin account starts with zero filters.
            #   - We query `Find-JiraFilter` with the exact seeded name instead of
            #     relying on fuzzy `-Name "test"` matching, because Cloud/DC
            #     deployments can differ in how broadly filter-name search matches.
            #   - The seeded filter intentionally does NOT use the shared
            #     `JiraPS-IntTest-` prefix. Parallel runspaces call
            #     `Remove-StaleTestResource`, which removes prefixed filters
            #     immediately and can race this test's freshly seeded filter.
            #     This test tracks the seed in `$script:createdFilters` and removes
            #     it in AfterAll.
            #   - `New-JiraFilter` is invoked with `-Favorite` so the filter is
            #     also discoverable by the bare `Find-JiraFilter` ("my filters")
            #     call: Jira Data Center's `/rest/api/2/filter/search` endpoint
            #     scopes the no-arg result set to the caller's *favourited*
            #     filters; a freshly-created-but-not-favourited private filter
            #     does not surface there.
            #   - The /filter/search endpoint is backed by a Lucene index and
            #     does not always reflect a just-created filter on the very
            #     next request (especially on the embedded H2-backed AMPS
            #     standalone image). We poll for up to 15 s to confirm the
            #     seeded filter is searchable before letting the dependent
            #     tests run; if it never becomes visible in that window we
            #     null out `$script:SeededFilter` so they self-skip with a
            #     clear message instead of asserting against an empty result.
            #   - We skip the seed entirely in read-only mode (e.g.
            #     `JIRA_TEST_READONLY=true` against a production-like Cloud
            #     account).
            $script:SeededFilter = $null
            if (-not $env.ReadOnly -and -not [string]::IsNullOrEmpty($fixtures.TestProject)) {
                try {
                    $seedName = "JiraPS-FindFilterSeed-$(Get-Date -Format 'yyyyMMddHHmmss')-$([Guid]::NewGuid().ToString('N').Substring(0, 6))"
                    $script:SeededFilter = New-JiraFilter `
                        -Name $seedName `
                        -JQL "project = $($fixtures.TestProject)" `
                        -Description "Auto-seeded by Filters.Integration.Tests.ps1 so Find-JiraFilter has data on a fresh deployment. Safe to delete." `
                        -Favorite
                    if ($script:SeededFilter) {
                        $null = $script:createdFilters.Add($script:SeededFilter)

                        $deadline = (Get-Date).AddSeconds(15)
                        $visible = $false
                        while ((Get-Date) -lt $deadline) {
                            $found = Find-JiraFilter -Name $script:SeededFilter.Name -ErrorAction SilentlyContinue
                            if ($found) { $visible = $true; break }
                            Start-Sleep -Milliseconds 500
                        }
                        if (-not $visible) {
                            Write-Warning "Filters integration tests: seeded filter [$($script:SeededFilter.Name)] never became visible to Find-JiraFilter within 15s; Find-JiraFilter assertions will self-skip."
                            $script:SeededFilter = $null
                        }
                    }
                }
                catch {
                    Write-Warning "Filters integration tests: failed to seed a baseline filter ($($_.Exception.Message)). Find-JiraFilter assertions will self-skip."
                }
            }
        }

        AfterAll {
            foreach ($filter in $script:createdFilters) {
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

                    $filter.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Filter'
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
                    # Query by the exact seeded name so this assertion is stable
                    # across Jira variants that apply different fuzzy-search rules.
                    $filters = Find-JiraFilter -Name $script:SeededFilter.Name

                    $filters | Should -Not -BeNullOrEmpty -Because "the BeforeAll seeded a filter and confirmed it is searchable by name"
                    @($filters | Select-Object -ExpandProperty Id) | Should -Contain $script:SeededFilter.Id -Because "Find-JiraFilter -Name should return the seeded filter"
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

                    $filter.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Filter'
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
