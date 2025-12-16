#requires -modules BuildHelpers
#requires -modules Pester

BeforeDiscovery {
    $projectPublicFunctions = (Get-ChildItem "$env:BHModulePath/Public/*.ps1").BaseName
    $projectPrivateFunctions = (Get-ChildItem "$env:BHModulePath/Private/*.ps1").BaseName
}

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

        $module = Get-Module $env:BHProjectName
        $testFiles = Get-ChildItem $PSScriptRoot -Include "*.Tests.ps1" -Recurse
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }


    Context "Public functions" {
        Context "<_>" -ForEach $projectPublicFunctions {
            It "has a test file" {
                $expectedTestFile = "$_.Unit.Tests.ps1"

                $testFiles.Name | Should -Contain $expectedTestFile
            }

            It "exports" {
                $expectedFunctionName = $_ -replace "\-", "-$($module.Prefix)"

                $module.ExportedCommands.keys | Should -Contain $expectedFunctionName
            }
        }
    }

    Context "Private functions" {
        Context "<_>" -ForEach $projectPrivateFunctions {
            It "does not export" {
                $expectedFunctionName = $_ -replace "\-", "-$($module.Prefix)"

                $module.ExportedCommands.keys | Should -Not -Contain $expectedFunctionName
            }
        }
    }

    Context "Project structure" {
        It "has all the public functions as a file in '$env:BHProjectName/Public'" {
            $publicFunctions = (Get-Module -Name $env:BHProjectName).ExportedFunctions.Keys
            foreach ($function in $publicFunctions) {
                # $function = $function.Replace((Get-Module -Name $env:BHProjectName).Prefix, '')

                (Get-ChildItem "$env:BHModulePath/Public").BaseName | Should -Contain $function
            }
        }
    }

    <#
    Context "Classes" {

        foreach ($class in ([AtlassianPS.ServerData].Assembly.GetTypes() | Where-Object IsClass)) {
            It "has a test file for $class" {
                $expectedTestFile = "$class.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            }
        }
    }

    Context "Enumeration" {

        foreach ($enum in ([AtlassianPS.ServerData].Assembly.GetTypes() | Where-Object IsEnum)) {
            It "has a test file for $enum" {
                $expectedTestFile = "$enum.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            }
        }
    }
#>

}
