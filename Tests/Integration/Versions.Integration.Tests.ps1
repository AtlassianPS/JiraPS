#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $testEnv = Initialize-IntegrationEnvironment
        $script:SkipWrite = $testEnv.ReadOnly
        $script:SkipVersionTests = [string]::IsNullOrEmpty($testEnv.TestVersion)
    }
}

InModuleScope JiraPS {
    Describe "Versions" -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
            $script:createdVersions = [System.Collections.ArrayList]::new()
        }

        AfterAll {
            foreach ($version in $createdVersions) {
                Remove-JiraVersion -Version $version -Force -ErrorAction SilentlyContinue
            }
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Describe "Get-JiraVersion" {
            Context "Project Versions" {
                It "retrieves versions for a project" {
                    # The auto-provisioned `TEST` project on Server CI starts without any
                    # versions, and the Cloud track's external project may also legitimately
                    # have none. Assert the call succeeds and only type-check the payload
                    # when there is data; the populated-shape case is covered both by the
                    # next `It` block and by the `New-JiraVersion` round-trip below.
                    { Get-JiraVersion -Project $fixtures.TestProject } | Should -Not -Throw

                    $versions = Get-JiraVersion -Project $fixtures.TestProject
                    if ($versions) {
                        @($versions)[0] | Should -BeOfType [PSCustomObject]
                    }
                }

                It "returns version objects with correct type" {
                    $versions = Get-JiraVersion -Project $fixtures.TestProject

                    if ($versions) {
                        @($versions)[0].PSObject.TypeNames[0] | Should -Be 'JiraPS.Version'
                    }
                }
            }

            Context "Specific Version" -Skip:$SkipVersionTests {
                It "retrieves a version by name" {
                    $version = Get-JiraVersion -Project $fixtures.TestProject -Name $fixtures.TestVersion

                    $version | Should -Not -BeNullOrEmpty
                    $version.Name | Should -Be $fixtures.TestVersion
                }
            }
        }

        Describe "New-JiraVersion" -Skip:$SkipWrite {
            Context "Version Creation" {
                It "creates a new version" {
                    $versionName = New-TestResourceName -Type "Version"

                    $version = New-JiraVersion -Project $fixtures.TestProject -Name $versionName
                    $null = $script:createdVersions.Add($version)

                    $version | Should -Not -BeNullOrEmpty
                    $version.Name | Should -Be $versionName
                }

                It "creates a version with description" {
                    $versionName = New-TestResourceName -Type "VersionDesc"

                    $version = New-JiraVersion -Project $fixtures.TestProject -Name $versionName -Description "Test description"
                    $null = $script:createdVersions.Add($version)

                    $version.Description | Should -Be "Test description"
                }

                It "creates a version with release date" {
                    $versionName = New-TestResourceName -Type "VersionDate"
                    $releaseDate = (Get-Date).AddDays(30)

                    $version = New-JiraVersion -Project $fixtures.TestProject -Name $versionName -ReleaseDate $releaseDate
                    $null = $script:createdVersions.Add($version)

                    $version | Should -Not -BeNullOrEmpty
                }

                It "returns version object with correct type" {
                    $versionName = New-TestResourceName -Type "VersionType"

                    $version = New-JiraVersion -Project $fixtures.TestProject -Name $versionName
                    $null = $script:createdVersions.Add($version)

                    $version.PSObject.TypeNames[0] | Should -Be 'JiraPS.Version'
                }
            }

            Context "Error Handling" {
                It "fails for non-existent project" {
                    { New-JiraVersion -Project 'NONEXISTENT' -Name 'Test' -ErrorAction Stop } |
                        Should -Throw
                }
            }
        }

        Describe "Set-JiraVersion" -Skip:$SkipWrite {
            # Each test creates its own version to avoid order-dependent state
            Context "Version Updates" {
                It "updates version description" {
                    $versionName = New-TestResourceName -Type "VersionSetDesc"
                    $version = New-JiraVersion -Project $fixtures.TestProject -Name $versionName
                    $null = $script:createdVersions.Add($version)

                    $newDescription = "Updated at $(Get-Date)"
                    Set-JiraVersion -Version $version -Description $newDescription

                    $updated = Get-JiraVersion -Project $fixtures.TestProject -Name $version.Name
                    $updated.Description | Should -Be $newDescription
                }

                It "marks version as released" {
                    $versionName = New-TestResourceName -Type "VersionSetRel"
                    $version = New-JiraVersion -Project $fixtures.TestProject -Name $versionName
                    $null = $script:createdVersions.Add($version)

                    Set-JiraVersion -Version $version -Released $true

                    $updated = Get-JiraVersion -Project $fixtures.TestProject -Name $version.Name
                    $updated.Released | Should -Be $true
                }

                It "marks version as archived" {
                    $versionName = New-TestResourceName -Type "VersionSetArch"
                    $version = New-JiraVersion -Project $fixtures.TestProject -Name $versionName
                    $null = $script:createdVersions.Add($version)

                    Set-JiraVersion -Version $version -Archived $true

                    $updated = Get-JiraVersion -Project $fixtures.TestProject -Name $version.Name
                    $updated.Archived | Should -Be $true
                }
            }
        }

        Describe "Remove-JiraVersion" -Skip:$SkipWrite {
            Context "Version Deletion" {
                It "deletes a version" {
                    $versionName = New-TestResourceName -Type "VersionDelete"
                    $version = New-JiraVersion -Project $fixtures.TestProject -Name $versionName

                    { Remove-JiraVersion -Version $version -Force -ErrorAction Stop } | Should -Not -Throw

                    # Verify the delete via the project-scoped `/rest/api/2/project/{key}/versions`
                    # endpoint, NOT via `Get-JiraVersion -Id`. The by-Id endpoint
                    # (`/rest/api/2/version/{id}`) on the moveworkforward AMPS standalone
                    # image keeps answering successfully out of an in-memory cache for
                    # well over 30s after the DELETE commits — confirmed by repeated
                    # 30s polls returning the version object every iteration. The
                    # project-scoped list query, however, reflects the delete on the
                    # very next read because it is regenerated from the project's
                    # canonical version table on each request. The list query is
                    # therefore the deterministic source of truth for "is this version
                    # still reachable" on both Server (AMPS H2) and Cloud, and is what
                    # the Jira UI itself uses to render the version dropdown after a
                    # delete. Keep a short poll budget to absorb any one-off lag, but
                    # the typical case completes on the first iteration.
                    $deadline = (Get-Date).AddSeconds(15)
                    $deleteObserved = $false
                    while ((Get-Date) -lt $deadline) {
                        $remaining = @(Get-JiraVersion -Project $fixtures.TestProject -ErrorAction SilentlyContinue) |
                            Where-Object { $_.Id -eq $version.Id }
                        if (-not $remaining) {
                            $deleteObserved = $true
                            break
                        }
                        Start-Sleep -Milliseconds 500
                    }
                    $deleteObserved | Should -BeTrue -Because "Remove-JiraVersion should drop the version from Get-JiraVersion -Project within 15s (verified via the project-scoped list endpoint, which reflects deletes deterministically — unlike the by-Id endpoint which AMPS H2 caches for >30s)"
                }
            }
        }
    }
}
