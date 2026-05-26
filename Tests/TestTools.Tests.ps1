#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

Describe 'Initialize-TestEnvironment' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/Helpers/TestTools.ps1"
    }

    It 'returns the path to the JiraPS manifest' {
        $path = Initialize-TestEnvironment
        $path | Should -Not -BeNullOrEmpty
        Test-Path $path | Should -BeTrue
        $path | Should -Match '\.psd1$'
    }

    It 'imports the module under test' {
        Initialize-TestEnvironment | Out-Null

        Get-Module JiraPS | Should -Not -BeNullOrEmpty
    }
}
