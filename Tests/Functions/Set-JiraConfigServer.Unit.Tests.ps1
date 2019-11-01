#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Set-JiraConfigServer" -Tag 'Unit' {

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

        $jiraServer = 'http://jiraserver.example.com'

        $script:serversConfig = "TestDrive:\serversConfig"
        $script:JiraServerConfigs = New-Object psobject

        It "stores the server address in the module session" {
            Set-JiraConfigServer -Server $jiraServer

            $config = $script:JiraServerConfigs.Default
            $config | Should -Not -BeNullOrEmpty
            $config.Server | Should -Be "$jiraServer/"
        }

        It "can store few servers configs" {
            Set-JiraConfigServer -Server $jiraServer -Name "Test"

            $config = $script:JiraServerConfigs.Test
            $config | Should -Not -BeNullOrEmpty
            $config.Server | Should -Be "$jiraServer/"
        }

        It "stores the server address in a config file" {
            $script:serversConfig | Should -Exist

            $config = Get-Content -Path $script:serversConfig -Raw | ConvertFrom-Json
            $config.Default.Server | Should -BeExactly "$jiraServer/"
            $config.Test.Server | Should -BeExactly "$jiraServer/"
        }
    }
}
