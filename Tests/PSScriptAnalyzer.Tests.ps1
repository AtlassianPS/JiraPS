#requires -modules BuildHelpers
#requires -modules Pester
#requires -modules PSScriptAnalyzer

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
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    $settingsPath = if ($script:isBuild) {
        "$env:BHBuildOutput/PSScriptAnalyzerSettings.psd1"
    }
    else {
        "$env:BHProjectPath/PSScriptAnalyzerSettings.psd1"
    }

    $Params = @{
        Path          = $env:BHModulePath
        Settings      = $settingsPath
        Severity      = @('Error', 'Warning')
        Recurse       = $true
        Verbose       = $false
        ErrorVariable = 'ErrorVariable'
        ErrorAction   = 'SilentlyContinue'
    }
    $ScriptWarnings = Invoke-ScriptAnalyzer @Params
    $scripts = Get-ChildItem $env:BHModulePath -Include *.ps1, *.psm1 -Recurse

    foreach ($Script in $scripts) {
        $RelPath = $Script.FullName.Replace($env:BHProjectPath, '') -replace '^\\', ''

        Context "$RelPath" {

            $Rules = $ScriptWarnings |
                Where-Object {$_.ScriptPath -like $Script.FullName} |
                Select-Object -ExpandProperty RuleName -Unique

            foreach ($rule in $Rules) {
                It "passes $rule" {
                    $BadLines = $ScriptWarnings |
                        Where-Object {$_.ScriptPath -like $Script.FullName -and $_.RuleName -like $rule} |
                        Select-Object -ExpandProperty Line
                    $BadLines | Should -Be $null
                }
            }

            $Exceptions = $null
            if ($ErrorVariable) {
                $Exceptions = $ErrorVariable.Exception.Message |
                    Where-Object {$_ -match [regex]::Escape($Script.FullName)}
            }

            It "has no parse errors" {
                foreach ($Exception in $Exceptions) {
                    $Exception | Should -BeNullOrEmpty
                }
            }
        }
    }
}
