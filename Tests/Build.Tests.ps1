#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "Validation of build environment" -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/Helpers/TestTools.ps1"

        Initialize-TestEnvironment
        $script:moduleToTest = Resolve-ModuleSource
        $script:moduleRoot = Resolve-ProjectRoot
    }

    Context "CHANGELOG" {
        BeforeAll {
            $changelogFile = "$moduleRoot/CHANGELOG.md"

            if (-not (Test-Path $changelogFile)) {
                throw "CHANGELOG.md file not found in the module root directory."
            }

            $script:changelogVersion = $null
            # Read the changelog file and extract the version
            # The regex pattern matches the version format in the changelog
            # Example: ## [1.0] - 2023-01-01
            # or: <h2>[1.0]</h2>
            foreach ($line in (Get-Content $changelogFile)) {
                if ($line -match "(?:##|\<h2.*?\>)\s*(?<Version>(\d+\.?){1,2})(\-(?<Prerelease>(?:alpha|beta|rc)\d*))?") {
                    $changelogVersion = $matches.Version
                    break
                }
            }
        }

        It "has a changelog file" {
            $changelogFile | Should -Exist
        }

        It "has a valid version in the changelog" {
            $changelogVersion             | Should -Not -BeNullOrEmpty
            [Version]($changelogVersion)  | Should -BeOfType [Version]
        }

        It "has a version changelog that matches the manifest version" {
            Metadata\Get-Metadata -Path $moduleToTest -PropertyName ModuleVersion | Should -BeLike "$changelogVersion*"
        }
    }
}
