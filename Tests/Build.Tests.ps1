#requires -modules BuildHelpers
#requires -modules Configuration
#requires -modules Pester

Describe "Validation of build environment" {

    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/..").Path
        if ($projectRoot -like "*Release") {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }

        Import-Module BuildHelpers
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

        $env:BHManifestToTest = $env:BHPSModuleManifest
        $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($script:isBuild) {
            $Pattern = [regex]::Escape($env:BHProjectPath)

            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        # Import-Module $env:BHManifestToTest
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    Context "CHANGELOG" {
        $changelogFile = if ($script:isBuild) {
            "$env:BHBuildOutput/$env:BHProjectName/CHANGELOG.md"
        }
        else {
            "$env:BHProjectPath/CHANGELOG.md"
        }

        foreach ($line in (Get-Content $changelogFile)) {
            if ($line -match "(?:##|\<h2.*?\>)\s*\[(?<Version>(\d+\.?){1,2})\]") {
                $changelogVersion = $matches.Version
                break
            }
        }

        It "has a changelog file" {
            $changelogFile | Should -Exist
        }

        It "has a valid version in the changelog" {
            $changelogVersion            | Should -Not -BeNullOrEmpty
            [Version]($changelogVersion)  | Should -BeOfType [Version]
        }

        It "has a version changelog that matches the manifest version" {
            Configuration\Get-Metadata -Path $env:BHManifestToTest -PropertyName ModuleVersion | Should -BeLike "$changelogVersion*"
        }
    }

    <# Context "AppVeyor" {
        $appveyorFile = "$env:BHProjectPath/appveyor.yml"
        $appveyorDevFile = "$env:BHProjectPath/Tools/dev-appveyor.yml"

        foreach ($line in (Get-Content $appveyorFile)) {
            # (?<Version>()) - non-capturing group, but named Version. This makes it
            # easy to reference the inside group later.

            if ($line -match '^\D*(?<Version>(\d+\.){1,3}\d+).\{build\}') {
                $appveyorVersion = $matches.Version
                break
            }
        }

        It "has an AppVeyor config file for master branch" {
            $appveyorFile | Should -Exist
            $appveyorFile | Should -FileContentMatchMultiline "branches:\r?\n\s+only:\r?\n\s+- master"
        }

        It "has an AppVeyor config file for development" {
            $appveyorDevFile | Should -Exist
            $appveyorDevFile | Should -FileContentMatchMultiline "branches:\r?\n\s+except:\r?\n\s+- master"
        }

        It "contains an authentication token (secure) for the PS Gallery" {
            $appveyorFile | Should -FileContentMatchMultiline "PSGalleryAPIKey:\r?\n\s+secure:"
        }

        foreach ($version in @("4.0", "5.1", "6.0")) {
            It "tests the project on Powersell version $version" {
                $appveyorFile | Should -FileContentMatch "PowershellVersion: `"$version"
            }
        }

        It "tests the project on Windows" {
            $appveyorFile | Should -FileContentMatch "APPVEYOR_BUILD_WORKER_IMAGE: Visual Studio"
        }

        It "tests the project on Ubuntu" {
            $appveyorFile | Should -FileContentMatch "APPVEYOR_BUILD_WORKER_IMAGE: Ubuntu"
        }

        It "has a valid version in the appveyor config" {
            $appveyorVersion           | Should -Not -BeNullOrEmpty
            [Version]($appveyorVersion) | Should -BeOfType [Version]
        }

        It "has a version for appveyor that matches the manifest version" {
            Configuration\Get-Metadata -Path $env:BHManifestToTest -PropertyName ModuleVersion | Should -BeLike "$appveyorVersion*"
        }
    } #>
}
