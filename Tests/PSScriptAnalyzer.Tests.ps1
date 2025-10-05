#requires -modules BuildHelpers
#requires -modules Pester
#requires -modules PSScriptAnalyzer
BeforeDiscovery {
    $scriptAnalyzerPaths = Get-ChildItem $env:BHModulePath -Include *.ps1, *.psm1 -Recurse |
        ForEach-Object {
        $relPath = $_.FullName.Replace($env:BHProjectPath, '') -replace '^\\', ''
        @{
            Path = $_.FullName
            RelPath = $relPath
        }
    }
}

Describe "PSScriptAnalyzer Tests" -Tag Unit {
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
        $settingsPath = if ($script:isBuild) {
            "$env:BHBuildOutput/PSScriptAnalyzerSettings.psd1"
        }
        else {
            "$env:BHProjectPath/PSScriptAnalyzerSettings.psd1"
        }

        $Params = @{
            Settings      = $settingsPath
            Severity      = @('Error', 'Warning')
            Verbose       = $false
            ErrorVariable = 'ErrorVariable'
            ErrorAction   = 'SilentlyContinue'
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }


    Context "PS Script Analyzer" {
        It "<RelPath>" -ForEach ($scriptAnalyzerPaths) {
            $results = Invoke-ScriptAnalyzer @Params -Path $Path
            $results | Should -BeNullOrEmpty
        }
    }
}
