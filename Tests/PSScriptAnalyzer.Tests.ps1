#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }
#requires -modules PSScriptAnalyzer

Describe "PSScriptAnalyzer Tests" -Tag "Unit" {
    BeforeDiscovery {
        . "$PSScriptRoot/Helpers/TestTools.ps1"

        $moduleRoot = Resolve-ProjectRoot
        ${/} = [System.IO.Path]::DirectorySeparatorChar

        $analyzerParams = @{
            Path        = $moduleRoot
            Settings    = "$moduleRoot/PSScriptAnalyzerSettings.psd1"
            Severity    = @('Error', 'Warning')
            Recurse     = $true
            Verbose     = $false
            ErrorAction = 'SilentlyContinue'
        }

        $script:analyzerResults = Invoke-ScriptAnalyzer @analyzerParams
        $script:analyzerWarnings = $analyzerResults | Where-Object {
            $_.ScriptPath -notlike "*${/}Release${/}JiraPS${/}JiraPS.psd1"
        }

        $script:moduleFiles = Get-ChildItem $moduleRoot -Recurse -File
    }

    Context "File <_.Name>" -ForEach $moduleFiles {
        BeforeAll {
            $script:file = $_
            $script:fileWarnings = $analyzerWarnings | Where-Object { $_.ScriptPath -eq $file.FullName }
        }

        It "has no PSScriptAnalyzer warnings" {
            $warningMessages = $fileWarnings | ForEach-Object {
                "Line $($_.Line): [$($_.RuleName)] $($_.Message)"
            }
            $warningMessages | Should -BeNullOrEmpty
        }
    }
}
