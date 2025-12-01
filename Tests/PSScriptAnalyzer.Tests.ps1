#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }
#requires -modules PSScriptAnalyzer

Describe "PSScriptAnalyzer Tests" -Tag "Unit" {
    BeforeDiscovery {
        $script:moduleToTestRoot = "$PSScriptRoot/.."
        ${/} = [System.IO.Path]::DirectorySeparatorChar

        $isaSplat = @{
            Path          = $moduleToTestRoot
            Settings      = "$moduleToTestRoot/PSScriptAnalyzerSettings.psd1"
            Severity      = @('Error', 'Warning')
            Recurse       = $true
            Verbose       = $false
            ErrorVariable = 'ErrorVariable'
            ErrorAction   = 'Stop'
        }
        $script:scriptWarnings = Invoke-ScriptAnalyzer @isaSplat | Where-Object { $_.ScriptPath -notlike "*${/}release${/}PSIni${/}PSIni.psd1" }
        $script:moduleFiles = Get-ChildItem $moduleToTestRoot -Recurse
    }

    It "has no script analyzer warnings" {
        $scriptWarnings | Should -HaveCount 0
    }

    Describe "File <_.Name>" -ForEach $moduleFiles {
        BeforeAll {
            $script:file = $_
        }
        It "has no script analyzer warnings" {
            $scriptWarnings |
                Where-Object { $_.ScriptPath -like $file.FullName } |
                ForEach-Object { "Problem in $($_.ScriptName) at line $($_.Line) with message: $($_.Message)" } |
                Should -BeNullOrEmpty
        }
    }

    It "has no parse errors" {
        $Exceptions = $null
        if ($ErrorVariable) {
            $Exceptions = $ErrorVariable.Exception.Message |
                Where-Object { $_ -match [regex]::Escape($Script.FullName) }
        }

        foreach ($Exception in $Exceptions) {
            $Exception | Should -BeNullOrEmpty
        }
    }
}
