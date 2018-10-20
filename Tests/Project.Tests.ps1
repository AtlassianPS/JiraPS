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
        Import-Module $env:BHManifestToTest
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    $module = Get-Module $env:BHProjectName
    $testFiles = Get-ChildItem $PSScriptRoot -Include "*.Tests.ps1" -Recurse
    # $loadedNamespace = [AtlassianPS.ServerData].Assembly.GetTypes() |
    #     Where-Object IsPublic

    Context "Public functions" {
        $publicFunctions = (Get-ChildItem "$env:BHModulePath/Public/*.ps1").BaseName

        foreach ($function in $publicFunctions) {

            It "has a test file for $function" {
                $expectedTestFile = "$function.Unit.Tests.ps1"

                $testFiles.Name | Should -Contain $expectedTestFile
            }

            It "exports $function" {
                $expectedFunctionName = $function -replace "\-", "-$($module.Prefix)"

                $module.ExportedCommands.keys | Should -Contain $expectedFunctionName
            }
        }
    }

    Context "Private functions" {
        $privateFunctions = (Get-ChildItem "$env:BHModulePath/Private/*.ps1").BaseName

        foreach ($function in $privateFunctions) {
            It "has a test file for $function" {
                # $expectedTestFile = "$function.Unit.Tests.ps1"

                # $testFiles.Name | Should -Contain $expectedTestFile
            }

            It "does not export $function" {
                $expectedFunctionName = $function -replace "\-", "-$($module.Prefix)"

                $module.ExportedCommands.keys | Should -Not -Contain $expectedFunctionName
            }
        }
    }

    # Context "Classes" {

    #     foreach ($class in ($loadedNamespace | Where-Object IsClass)) {
    #         It "has a test file for $class" {
    #             $expectedTestFile = "$class.Unit.Tests.ps1"
    #             $testFiles.Name | Should -Contain $expectedTestFile
    #         }
    #     }
    # }

    # Context "Enumeration" {

    #     foreach ($enum in ($loadedNamespace | Where-Object IsEnum)) {
    #         It "has a test file for $enum" {
    #             $expectedTestFile = "$enum.Unit.Tests.ps1"
    #             $testFiles.Name | Should -Contain $expectedTestFile
    #         }
    #     }
    # }

    Context "Project stucture" {
        It "has a README" {
            Test-Path "$env:BHProjectPath/README.md" | Should -Be $true
        }

        It "defines the homepage's frontmatter in the README" {
            Get-Content "$env:BHProjectPath/README.md" | Should -Not -BeNullOrEmpty
            "$env:BHProjectPath/README.md" | Should -FileContentMatchExactly "layout: module"
            "$env:BHProjectPath/README.md" | Should -FileContentMatchExactly "permalink: /module/$env:BHProjectName/"
        }

        It "uses the MIT license" {
            Test-Path "$env:BHProjectPath/LICENSE" | Should -Be $true
            Get-Content "$env:BHProjectPath/LICENSE" | Should -Not -BeNullOrEmpty
            "$env:BHProjectPath/LICENSE" | Should -FileContentMatchExactly "MIT License"
            "$env:BHProjectPath/LICENSE" | Should -FileContentMatch "Copyright \(c\) 20\d{2} AtlassianPS"

        }

        It "has a .gitignore" {
            Test-Path "$env:BHProjectPath/.gitignore" | Should -Be $true
        }

        It "has a .gitattributes" {
            Test-Path "$env:BHProjectPath/.gitattributes" | Should -Be $true
        }

        It "has all the public functions as a file in '$env:BHProjectName/Public'" {
            $module = (Get-Module -Name $env:BHProjectName)
            $publicFunctions = $module.ExportedFunctions.Keys

            foreach ($function in $publicFunctions) {
                if ($module.Prefix) {
                    $function = $function.Replace($module.Prefix, '')
                }

                (Get-ChildItem "$env:BHModulePath/Public").BaseName | Should -Contain $function
            }
        }
    }
}
