#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe 'Tools/setup.ps1' -Tag Unit {
    It 'delegates dependency install and analyzer settings sync to shared standards commands' {
        $projectRoot = if (
            $env:BHProjectPath -and
            (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'CODEOWNERS'))
        ) {
            (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
        }
        else {
            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS')) {
                    break
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            if (-not $candidate -or -not (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS'))) {
                throw "Could not resolve repository root from '$PSScriptRoot'."
            }

            $candidate
        }

        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'JiraPS'
        $mockModulePath = Join-Path -Path $harnessRoot -ChildPath 'mockModules/AtlassianPS.Standards/0.1.6'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'setup.ps1'
        $installCapturePath = Join-Path -Path $TestDrive -ChildPath 'setup-install.json'
        $syncCapturePath = Join-Path -Path $TestDrive -ChildPath 'setup-sync.txt'
        $escapedInstallCapturePath = $installCapturePath.Replace("'", "''")
        $escapedSyncCapturePath = $syncCapturePath.Replace("'", "''")

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force
        $null = New-Item -Path $mockModulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'setup.ps1') -Destination $scriptPath
        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'SharedStandards.ps1') -Destination (Join-Path -Path $toolsPath -ChildPath 'SharedStandards.ps1')

        Set-Content -LiteralPath (Join-Path -Path $toolsPath -ChildPath 'build.requirements.psd1') -Value @'
@(
    @{ ModuleName = "AtlassianPS.Standards"; RequiredVersion = "0.1.6" }
    @{ ModuleName = "InvokeBuild"; RequiredVersion = "5.14.23" }
)
'@

        Set-Content -LiteralPath (Join-Path -Path $modulePath -ChildPath 'JiraPS.psd1') -Value @'
@{
    RootModule      = 'JiraPS.psm1'
    ModuleVersion   = '3.0'
    RequiredModules = @()
}
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psm1') -Value @"
function Install-AtlassianPSDependencyRequirement {
    [CmdletBinding()]
    param(
        [String]`$BuildRequirementsPath,
        [String]`$ManifestPath
    )

    [PSCustomObject]@{
        BuildRequirementsPath = `$BuildRequirementsPath
        ManifestPath          = `$ManifestPath
    } | ConvertTo-Json -Compress | Set-Content -LiteralPath '$escapedInstallCapturePath'
}

function Sync-AtlassianPSScriptAnalyzerSettings {
    [CmdletBinding()]
    param(
        [String]`$DestinationPath
    )

    Set-Content -LiteralPath '$escapedSyncCapturePath' -Value `$DestinationPath
    return `$DestinationPath
}

Export-ModuleMember -Function Install-AtlassianPSDependencyRequirement, Sync-AtlassianPSScriptAnalyzerSettings
"@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psd1') -Value @'
@{
    RootModule        = 'AtlassianPS.Standards.psm1'
    ModuleVersion     = '0.1.6'
    GUID              = '5d8bdca8-6d20-47b5-a302-f6f51cf96270'
    FunctionsToExport = @('*')
}
'@

        Mock -CommandName Get-PSRepository -MockWith { [PSCustomObject]@{ Name = 'PSGallery' } }
        Mock -CommandName Register-PSRepository -MockWith {}
        Mock -CommandName Install-Module -MockWith {}

        $moduleSearchPath = Join-Path -Path $harnessRoot -ChildPath 'mockModules'
        $originalModulePath = $env:PSModulePath
        $env:PSModulePath = "$moduleSearchPath$([System.IO.Path]::PathSeparator)$originalModulePath"
        try {
            & $scriptPath | Out-Null
        }
        finally {
            $env:PSModulePath = $originalModulePath
            Remove-Module -Name 'AtlassianPS.Standards' -Force -ErrorAction SilentlyContinue
        }

        $capturedInstall = Get-Content -LiteralPath $installCapturePath -Raw | ConvertFrom-Json
        $capturedSyncPath = (Get-Content -LiteralPath $syncCapturePath -Raw).TrimEnd("`r", "`n")

        $capturedInstall.BuildRequirementsPath | Should -Be (Join-Path -Path $harnessRoot -ChildPath 'Tools/build.requirements.psd1')
        $capturedInstall.ManifestPath | Should -Be (Join-Path -Path $harnessRoot -ChildPath 'JiraPS/JiraPS.psd1')
        $capturedSyncPath | Should -Be (Join-Path -Path $harnessRoot -ChildPath 'PSScriptAnalyzerSettings.psd1')
    }

    It 'fails fast when shared installer emits a non-terminating error' {
        $projectRoot = if (
            $env:BHProjectPath -and
            (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'CODEOWNERS'))
        ) {
            (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
        }
        else {
            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS')) {
                    break
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            if (-not $candidate -or -not (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS'))) {
                throw "Could not resolve repository root from '$PSScriptRoot'."
            }

            $candidate
        }

        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'JiraPS'
        $mockModulePath = Join-Path -Path $harnessRoot -ChildPath 'mockModules/AtlassianPS.Standards/0.1.6'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'setup.ps1'

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force
        $null = New-Item -Path $mockModulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'setup.ps1') -Destination $scriptPath
        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'SharedStandards.ps1') -Destination (Join-Path -Path $toolsPath -ChildPath 'SharedStandards.ps1')

        Set-Content -LiteralPath (Join-Path -Path $toolsPath -ChildPath 'build.requirements.psd1') -Value @'
@(
    @{ ModuleName = "AtlassianPS.Standards"; RequiredVersion = "0.1.6" }
    @{ ModuleName = "InvokeBuild"; RequiredVersion = "5.14.23" }
)
'@

        Set-Content -LiteralPath (Join-Path -Path $modulePath -ChildPath 'JiraPS.psd1') -Value @'
@{
    RootModule      = 'JiraPS.psm1'
    ModuleVersion   = '3.0'
    RequiredModules = @()
}
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psm1') -Value @'
function Install-AtlassianPSDependencyRequirement {
    [CmdletBinding()]
    param(
        [String]$BuildRequirementsPath,
        [String]$ManifestPath
    )

    Write-Error -Message "simulated setup failure"
}

function Sync-AtlassianPSScriptAnalyzerSettings {
    [CmdletBinding()]
    param(
        [String]$DestinationPath
    )

    return $DestinationPath
}

Export-ModuleMember -Function Install-AtlassianPSDependencyRequirement, Sync-AtlassianPSScriptAnalyzerSettings
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psd1') -Value @'
@{
    RootModule        = 'AtlassianPS.Standards.psm1'
    ModuleVersion     = '0.1.6'
    GUID              = '5d8bdca8-6d20-47b5-a302-f6f51cf96270'
    FunctionsToExport = @('*')
}
'@

        Mock -CommandName Get-PSRepository -MockWith { [PSCustomObject]@{ Name = 'PSGallery' } }
        Mock -CommandName Register-PSRepository -MockWith {}
        Mock -CommandName Install-Module -MockWith {}

        $moduleSearchPath = Join-Path -Path $harnessRoot -ChildPath 'mockModules'
        $originalModulePath = $env:PSModulePath
        $env:PSModulePath = "$moduleSearchPath$([System.IO.Path]::PathSeparator)$originalModulePath"
        try {
            {
                & $scriptPath | Out-Null
            } | Should -Throw -ExpectedMessage '*simulated setup failure*'
        }
        finally {
            $env:PSModulePath = $originalModulePath
            Remove-Module -Name 'AtlassianPS.Standards' -Force -ErrorAction SilentlyContinue
        }
    }
}
