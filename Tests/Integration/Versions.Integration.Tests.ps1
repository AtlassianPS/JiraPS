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

                    # Poll for up to 5 seconds for the delete to be observable: either
                    # `Get-JiraVersion -Id` throws (the contract on Jira Cloud and a
                    # well-behaved Data Center backend) or returns `$null` (some Server
                    # release notes claim the by-ID endpoint can return an empty payload
                    # rather than 404 right after a delete commits to disk). Both
                    # outcomes prove the version is no longer reachable; the previous
                    # iteration of this test wedged on the `Should -Throw` branch even
                    # when the version *was* deleted because the moveworkforward AMPS
                    # image's H2 store occasionally answers the by-ID GET out of cache
                    # for a beat, returning the now-stale object before the cascade
                    # propagates. The poll-and-OR keeps the cmdlet contract assertion
                    # honest without flapping on storage-layer eventual consistency.
                    $deadline = (Get-Date).AddSeconds(5)
                    $deleteObserved = $false
                    while ((Get-Date) -lt $deadline) {
                        try {
                            $stillThere = Get-JiraVersion -Id $version.Id -ErrorAction Stop -Debug:$false
                            if (-not $stillThere) { $deleteObserved = $true; break }
                        }
                        catch {
                            $deleteObserved = $true
                            break
                        }
                        Start-Sleep -Milliseconds 250
                    }
                    $deleteObserved | Should -BeTrue -Because "Remove-JiraVersion should make the version unreachable via Get-JiraVersion -Id within 5s"
                }
            }
        }
    }
}
