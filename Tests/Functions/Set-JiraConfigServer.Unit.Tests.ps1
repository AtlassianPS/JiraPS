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

        $configFile = Join-Path -Path $TestDrive -ChildPath 'config.xml'
        Set-JiraConfigServer -Server $jiraServer -ConfigFile $configFile

        It "Ensures that a config.xml file exists" {
            $configFile | Should Exist
        }

        $xml = New-Object -TypeName Xml
        $xml.Load($configFile)
        $xmlServer = $xml.Config.Server

        It "Ensures that the XML file has a Config.Server element" {
            $xmlServer | Should Not BeNullOrEmpty
        }

        It "Sets the config file's Server value " {
            $xmlServer | Should Be $jiraServer
        }

        It "Trims whitespace from the provided Server parameter" {
            Set-JiraConfigServer -Server "$jiraServer " -ConfigFile $configFile
            $xml = New-Object -TypeName Xml
            $xml.Load($configFile)
            $xml.Config.Server | Should Be $jiraServer
        }

        It "Trims trailing slasher from the provided Server parameter" {
            Set-JiraConfigServer -Server "$jiraServer/" -ConfigFile $configFile
            $xml = New-Object -TypeName Xml
            $xml.Load($configFile)
            $xml.Config.Server | Should Be $jiraServer
        }
    }
}
