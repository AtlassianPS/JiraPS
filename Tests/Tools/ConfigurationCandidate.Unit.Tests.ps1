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
        {
            & (Join-Path $script:tools 'Import-ConfigurationCandidate.ps1') -PackagePath $package -Version 0.3.0-alpha0001 -ModuleRoot $destination -ExpectedSha256 ('0' * 64)
        } |
            Should -Throw '*hash*'

        Test-Path $destination | Should -BeFalse
    }

    It 'rejects an explicitly selected package when a runtime is already loaded' {
        Mock Install-Module {}
        Mock Get-PSRepository {
            [PSCustomObject]@{
                Name               = 'PSGallery'
                InstallationPolicy = 'Trusted'
            }
        }
        Mock Save-Module {}
        {
            & (Join-Path $script:tools 'setup.ps1') -RuntimePSEdition Core -ConfigurationCandidatePackage 'candidate.zip' -ConfigurationCandidateSha256 ('0' * 64)
        } |
            Should -Throw '*fresh process*'
        Should -Invoke Save-Module -Times 0
    }

    It 'provisions dependencies outside the source tree unless a root is supplied: <ExplicitRoot>' -ForEach @(
        @{ ExplicitRoot = $false }
        @{ ExplicitRoot = $true }
    ) {
        Mock Install-Module {}
        Mock Import-Module {} -ParameterFilter { $Name -eq 'AtlassianPS.Standards' }
        Mock Get-Module { $null } -ParameterFilter { $Name -eq 'AtlassianPS.Configuration' }
        Mock Get-PSRepository { [PSCustomObject]@{ Name = 'PSGallery'; InstallationPolicy = 'Trusted' } }
        Mock New-Item {} -ParameterFilter { $ItemType -eq 'Directory' }
        Mock Save-Module { throw 'Provisioning destination captured' }

        $parameters = @{ RuntimePSEdition = 'Core' }
        if ($ExplicitRoot) { $parameters.ConfigurationCandidateRoot = Join-Path $TestDrive 'selected-modules' }

        {
            & (Join-Path $script:tools 'setup.ps1') @parameters
        } | Should -Throw 'Provisioning destination captured'

        Should -Invoke Save-Module -Exactly -Times 1 -ParameterFilter {
            $Name -eq 'AtlassianPS.Configuration' -and
            $(if ($ExplicitRoot) { $Path -eq $parameters.ConfigurationCandidateRoot }
                else { (Split-Path $Path -Parent).TrimEnd('/\\') -eq ([IO.Path]::GetTempPath()).TrimEnd('/\\') })
        }
    }
}
