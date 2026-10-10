#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

Describe "General project validation" -Tag Unit {
    BeforeAll {
        Remove-Module JiraPS -ErrorAction SilentlyContinue

        $script:manifest = Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop -WarningAction SilentlyContinue

        $configFile = ("{0}/AtlassianPS/JiraPS/server_config" -f [Environment]::GetFolderPath('ApplicationData'))
        $script:oldConfig = if (Test-Path $configFile) { Get-Content $configFile -Raw } else { $null }
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

    It "module uses the previous server config when loaded" {
        Import-Module $moduleToTest -Force

        $expected = if ($script:oldConfig) { ([uri]($script:oldConfig -split '\r?\n')[0].Trim()).AbsoluteUri.TrimEnd('/') } else { '' }
        Get-JiraConfigServer | Should -Be $expected
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
