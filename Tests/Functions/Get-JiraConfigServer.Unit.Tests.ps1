#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Get-JiraConfigServer" -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
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
        Import-Module $env:BHManifestToTest
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

        $sampleServerConfig = New-Object -TypeName psobject

        $script:JiraServerConfigs = @{}

        It "returns the server stored in the module's session" {
            $script:JiraServerConfigs =
                New-Object -TypeName psobject |
                Add-Member -NotePropertyName "Default" -NotePropertyValue $sampleServerConfig -PassThru

            Get-JiraConfigServer | Should -BeExactly $sampleServerConfig
        }

        It "return the named server stored in the module's session" {
            $script:JiraServerConfigs =
                New-Object -TypeName psobject |
                Add-Member -NotePropertyName "Test" -NotePropertyValue $sampleServerConfig -PassThru

            Get-JiraConfigServer -Name "Test" | Should -BeExactly $sampleServerConfig
        }

        It "throws an error when desired config does not exist" {
            { Get-JiraConfigServer -Name "TestB" } | Should -Throw
        }
    }
}
