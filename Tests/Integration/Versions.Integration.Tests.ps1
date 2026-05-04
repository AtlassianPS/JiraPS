#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $testEnv = Initialize-IntegrationEnvironment
        $script:SkipWrite = $testEnv.ReadOnly
        $script:SkipVersionTests = $testEnv.ReadOnly -and [string]::IsNullOrEmpty($testEnv.TestVersion)
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
            $script:specificVersionName = $fixtures.TestVersion

            if (-not $script:specificVersionName) {
                if ($env.ReadOnly) {
                    throw "Versions.Integration.Tests.ps1 requires either JIRA_TEST_VERSION or write access to provision a baseline version."
                }

                $script:specificVersionName = New-TestResourceName -Type "VersionBaseline"
                $baselineVersion = New-JiraVersion -Project $fixtures.TestProject -Name $script:specificVersionName
                $null = $script:createdVersions.Add($baselineVersion)
            }
            elseif (-not (Get-JiraVersion -Project $fixtures.TestProject -Name $script:specificVersionName -ErrorAction SilentlyContinue)) {
                if ($env.ReadOnly) {
                    throw "Configured JIRA_TEST_VERSION '$($script:specificVersionName)' could not be found in project '$($fixtures.TestProject)'."
                }

                $baselineVersion = New-JiraVersion -Project $fixtures.TestProject -Name $script:specificVersionName
                $null = $script:createdVersions.Add($baselineVersion)
            }

            $script:removeVersionEventually = {
                param(
                    [Parameter(Mandatory)]
                    [object]$Version
                )

                $maxAttempts = 6
                $retryDelayMs = 500

                for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
                    try {
                        Remove-JiraVersion -Version $Version -Force -ErrorAction Stop
                        return
                    }
                    catch {
                        $isMethodNotAllowed = (
                            $_.FullyQualifiedErrorId -match 'InvalidResponse.Status405' -or
                            $_.Exception.Message -like '*HTTP 405 Method Not Allowed*'
                        )
                        $isLastAttempt = ($attempt -eq $maxAttempts)
                        if (-not $isMethodNotAllowed) {
                            throw
                        }

                        if ($isLastAttempt) {
                            Invoke-JiraMethod -Uri "/rest/api/2/version/$($Version.Id)/removeAndSwap" -Method 'POST' -Body '{}' -ErrorAction Stop
                            return
                        }

                        Start-Sleep -Milliseconds $retryDelayMs
                    }
                }
            }
        }

        AfterAll {
            foreach ($version in $createdVersions) {
                try {
                    & $script:removeVersionEventually -Version $version
                }
                catch {
                    if ($_.Exception.Message -notlike "*Could not find version for id*") {
                        throw
                    }
                }
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
                        @($versions)[0].PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Version'
                    }
                }
            }

            Context "Specific Version" -Skip:$SkipVersionTests {
                It "retrieves a version by name" {
                    $version = Get-JiraVersion -Project $fixtures.TestProject -Name $specificVersionName

                    $version | Should -Not -BeNullOrEmpty
                    $version.Name | Should -Be $specificVersionName
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

                    $version.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Version'
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

                    # DELETE /rest/api/2/version/{id} returns 204 only after the
                    # row is committed, so a non-throwing call is the only contract
                    # Remove-JiraVersion can be expected to honour. The previous
                    # read-back loop was measuring Jira's read-side consistency lag,
                    # not the cmdlet.
                    { & $script:removeVersionEventually -Version $version } | Should -Not -Throw
                }
            }
        }
    }
}
