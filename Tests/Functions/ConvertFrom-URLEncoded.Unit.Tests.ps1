#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "ConvertFrom-URLEncoded" -Tag 'Unit' {

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

        Context "Sanity checking" {
            $command = Get-Command -Name ConvertFrom-URLEncoded

            defParam $command 'InputString'
        }
        Context "Handling of Inputs" {
            It "does not not allow a null or empty input" {
                { ConvertFrom-URLEncoded -InputString $null } | Should Throw
                { ConvertFrom-URLEncoded -InputString "" } | Should Throw
            }
            It "accepts pipeline input" {
                { "lorem ipsum" | ConvertFrom-URLEncoded } | Should Not Throw
            }
            It "accepts multiple InputStrings" {
                { ConvertFrom-URLEncoded -InputString "lorem", "ipsum" } | Should Not Throw
                { "lorem", "ipsum" | ConvertFrom-URLEncoded } | Should Not Throw
            }
        }
        Context "Handling of Outputs" {
            It "returns as many objects as inputs where provided" {
                $r1 = ConvertFrom-URLEncoded -InputString "lorem"
                $r2 = "lorem", "ipsum" | ConvertFrom-URLEncoded
                $r3 = ConvertFrom-URLEncoded -InputString "lorem", "ipsum", "dolor"

                @($r1).Count | Should Be 1
                @($r2).Count | Should Be 2
                @($r3).Count | Should Be 3
            }
            It "decodes URL encoded strings" {
                $output = ConvertFrom-URLEncoded -InputString "Hello%20World%3F"
                $output | Should Be 'Hello World?'
            }
        }
    }
}
