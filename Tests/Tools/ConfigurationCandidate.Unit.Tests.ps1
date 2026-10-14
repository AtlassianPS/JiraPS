#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }
Describe 'Configuration candidate provisioning' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/TestTools.ps1"
        $script:moduleToTest = Initialize-TestEnvironment
        $script:tools = Join-Path (Resolve-ProjectRoot) 'Tools'
    }
    It 'rejects a changed archive before extraction' {
        $package = Join-Path $TestDrive 'candidate.zip'
        Set-Content -LiteralPath $package -Value 'untrusted archive'
        $destination = Join-Path $TestDrive 'extracted'
        { & (Join-Path $script:tools 'Import-ConfigurationCandidate.ps1') -PackagePath $package -Version 0.3.0-alpha0001 -ModuleRoot $destination -ExpectedSha256 ('0' * 64) } |
            Should -Throw '*hash*'
        Test-Path $destination | Should -BeFalse
    }
    It 'rejects an explicitly selected package when a runtime is already loaded' {
        Mock Install-Module {}
        Mock Get-PSRepository { [PSCustomObject]@{ Name = 'PSGallery'; InstallationPolicy = 'Trusted' } }
        Mock Save-Module {}
        { & (Join-Path $script:tools 'setup.ps1') -RuntimePSEdition Core -ConfigurationCandidatePackage 'candidate.zip' -ConfigurationCandidateSha256 ('0' * 64) } |
            Should -Throw '*fresh process*'
        Should -Invoke Save-Module -Times 0
    }
}
