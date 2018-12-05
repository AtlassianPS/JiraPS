#requires -modules BuildHelpers
#requires -modules Pester

Describe "General project validation" -Tag Unit {

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

    It "passes Test-ModuleManifest" {
        { Test-ModuleManifest -Path $env:BHManifestToTest -ErrorAction Stop } | Should -Not -Throw
    }

    It "module '$env:BHProjectName' can import cleanly" {
        { Import-Module $env:BHManifestToTest } | Should Not Throw
    }

    It "module '$env:BHProjectName' exports functions" {
        Import-Module $env:BHManifestToTest

        (Get-Command -Module $env:BHProjectName | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It "module uses the correct root module" {
        Get-Metadata -Path $env:BHManifestToTest -PropertyName RootModule | Should -Be 'JiraPS.psm1'
    }

    It "module uses the correct guid" {
        Get-Metadata -Path $env:BHManifestToTest -PropertyName Guid | Should -Be '4bf3eb15-037e-43b7-9e47-20a30436324f'
    }

    It "module uses a valid version" {
        [Version](Get-Metadata -Path $env:BHManifestToTest -PropertyName ModuleVersion) | Should -Not -BeNullOrEmpty
        [Version](Get-Metadata -Path $env:BHManifestToTest -PropertyName ModuleVersion) | Should -BeOfType [Version]
    }

    # It "module is imported with default prefix" {
    #     $prefix = Get-Metadata -Path $env:BHManifestToTest -PropertyName DefaultCommandPrefix

    #     Import-Module $env:BHManifestToTest -Force -ErrorAction Stop
    #     (Get-Command -Module $env:BHProjectName).Name | ForEach-Object {
    #         $_ | Should -Match "\-$prefix"
    #     }
    # }

    # It "module is imported with custom prefix" {
    #     $prefix = "Wiki"

    #     Import-Module $env:BHManifestToTest -Prefix $prefix -Force -ErrorAction Stop
    #     (Get-Command -Module $env:BHProjectName).Name | ForEach-Object {
    #         $_ | Should -Match "\-$prefix"
    #     }
    # }
}
