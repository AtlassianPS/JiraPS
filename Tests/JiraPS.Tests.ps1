#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

Describe "General project validation" -Tag Unit {
    BeforeAll {
        Remove-Module JiraPS -ErrorAction SilentlyContinue

        $script:manifest = Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop -WarningAction SilentlyContinue
    }

    AfterEach {
        Remove-Module JiraPS -ErrorAction SilentlyContinue
    }

    It "passes Test-ModuleManifest" {
        { Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop } | Should -Not -Throw
    }

    It "module 'JiraPS' can import cleanly" {
        { Import-Module $moduleToTest } | Should -Not -Throw
    }

    It "module 'JiraPS' exports functions" {
        Import-Module $moduleToTest

        (Get-Command -Module JiraPS | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It "module uses the correct root module" {
        $manifest.RootModule | Should -Be 'JiraPS.psm1'
    }

    It "module uses the correct guid" {
        $manifest.Guid | Should -Be '4bf3eb15-037e-43b7-9e47-20a30436324f'
    }

    It "module uses a valid version" {
        $manifest.Version | Should -Not -BeNullOrEmpty
        [Version]($manifest.Version) | Should -BeOfType [Version]
    }

    It "does not import legacy server configuration during initialization" {
        $testServerConfig = Join-Path $TestDrive 'server_config'
        Set-Content -LiteralPath $testServerConfig -Value 'https://saved-config.example/'

        # Import in an isolated runspace so earlier tests cannot leave module mocks behind.
        $powerShell = [PowerShell]::Create()
        try {
            $null = $powerShell.AddScript({
                    param($modulePath, $fixturePath)
                    $script:configFile = "{0}/AtlassianPS/JiraPS/server_config" -f [Environment]::GetFolderPath('ApplicationData', 'Create')
                    $script:fixturePath = $fixturePath
                    $script:configReads = 0

                    function global:Test-Path {
                        [CmdletBinding()]
                        param([string]$Path, [string]$LiteralPath, [Alias('Type')][Microsoft.PowerShell.Commands.TestPathType]$PathType)
                        if ($Path -eq $script:configFile) { return $true }
                        Microsoft.PowerShell.Management\Test-Path @PSBoundParameters
                    }

                    function global:Get-Content {
                        [CmdletBinding()]
                        param([string]$Path, [string]$LiteralPath, [string]$Encoding, [switch]$Raw)
                        if ($Path -eq $script:configFile) {
                            $script:configReads++
                            return [IO.File]::ReadAllText($script:fixturePath)
                        }
                        Microsoft.PowerShell.Management\Get-Content @PSBoundParameters
                    }

                    Import-Module $modulePath -Force -ErrorAction Stop
                    [PSCustomObject]@{
                        LegacyCommandCount = @(Get-Command -Module JiraPS | Where-Object { $_.Name -in @('Get-JiraConfigServer', 'Set-JiraConfigServer', 'Get-JiraSession', 'New-JiraSession', 'Set-JiraSession', 'Remove-JiraSession') }).Count
                        Reads              = $script:configReads
                    }
                }).AddArgument($moduleToTest).AddArgument($testServerConfig)
            $result = $powerShell.Invoke()
            if ($powerShell.HadErrors) { throw $powerShell.Streams.Error[0] }

            $result.LegacyCommandCount | Should -Be 0
            $result.Reads | Should -Be 0
        }
        finally {
            $powerShell.Dispose()
        }
    }

    It "module manifest uses a semantic version" {
        $manifest.Version | Should -Match '^\d+\.\d+\.\d+(?:-.+)?$'
    }

    # It "module is imported with default prefix" {
    #     $prefix = Get-Metadata -Path $moduleToTest -PropertyName DefaultCommandPrefix

    #     Import-Module $moduleToTest -Force -ErrorAction Stop
    #     (Get-Command -Module JiraPS).Name | ForEach-Object {
    #         $_ | Should -Match "\-$prefix"
    #     }
    # }

    # It "module is imported with custom prefix" {
    #     $prefix = "Wiki"

    #     Import-Module $moduleToTest -Prefix $prefix -Force -ErrorAction Stop
    #     (Get-Command -Module JiraPS).Name | ForEach-Object {
    #         $_ | Should -Match "\-$prefix"
    #     }
    # }
}
