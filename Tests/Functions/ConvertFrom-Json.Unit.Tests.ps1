#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

BeforeDiscovery {
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

InModuleScope JiraPS {
    Describe "ConvertFrom-Json" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defProp / checkType / castsToString)

            $sampleJson = '{"id":"issuetype","name":"Issue Type","custom":false,"orderable":true,"navigable":true,"searchable":true,"clauseNames":["issuetype","type"],"schema":{"type":"issuetype","system":"issuetype"}}'
            $sampleObject = ConvertFrom-Json -InputObject $sampleJson
        }

        It "Creates a PSObject out of JSON input" {
            $sampleObject | Should -Not -BeNullOrEmpty
        }

        It "Defines the expected properties" {
            defProp $sampleObject 'Id' 'issuetype'
            defProp $sampleObject 'Name' 'Issue Type'
            defProp $sampleObject 'Custom' $false
        }

        Context "Sanity checking" {
            It "Does not crash on a null or empty input" {
                { ConvertFrom-Json -InputObject '' } | Should -Not -Throw
            }

            It "Accepts pipeline input" {
                { @($sampleJson, $sampleJson) | ConvertFrom-Json } | Should -Not -Throw
            }

            It "Provides the same output as ConvertFrom-Json for JSON strings the latter can handle" {
                # Make sure we've got our head screwed on straight. If it's a short enough JSON string that ConvertFrom-Json can handle it, this function should provide identical output to the native one.

                $sampleNative = ConvertFrom-Json -InputObject $sampleJson
                foreach ($p in $sampleObject.PSObject.Properties.Name) {
                    # Force converting everything to a string isn't the best test of equality, but it's good enough for what we need here.
                    "$($sampleObject.$p)" | Should -Be "$($sampleNative.$p)"
                }
            }
        }
    }
}
