#requires -Module PowerShellGet

[CmdletBinding()]
param()

$psScriptAnalyzerSettingsUri = 'https://raw.githubusercontent.com/AtlassianPS/.github/master/standards/PSScriptAnalyzerSettings.psd1'
$psScriptAnalyzerSettingsSha256 = '89207270e49dd58895d146c7182e661c55c4092f3d3cdc280a4de26f407daa6e'
$psScriptAnalyzerSettingsPath = Join-Path $PSScriptRoot '..' 'PSScriptAnalyzerSettings.psd1'

function Sync-PSScriptAnalyzerSettings {
    [CmdletBinding()]
    param()

    Write-Output "Syncing PSScriptAnalyzer settings from AtlassianPS/.github"

    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) "PSScriptAnalyzerSettings.$([System.Guid]::NewGuid().ToString('N')).psd1"
    try {
        $invokeWebRequestParams = @{
            Uri         = $psScriptAnalyzerSettingsUri
            OutFile     = $tempPath
            ErrorAction = 'Stop'
        }

        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            $invokeWebRequestParams.UseBasicParsing = $true
        }

        Invoke-WebRequest @invokeWebRequestParams

        $downloadHash = (Get-FileHash -Path $tempPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($downloadHash -ne $psScriptAnalyzerSettingsSha256) {
            throw "Downloaded PSScriptAnalyzer settings hash mismatch. Expected '$psScriptAnalyzerSettingsSha256' but received '$downloadHash'."
        }

        Move-Item -Path $tempPath -Destination $psScriptAnalyzerSettingsPath -Force
    }
    catch {
        if (Test-Path -Path $tempPath) {
            Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
        }

        if (Test-Path -Path $psScriptAnalyzerSettingsPath) {
            Write-Warning "Unable to refresh PSScriptAnalyzer settings from pinned source. Using existing local file at '$psScriptAnalyzerSettingsPath'."
            Write-Warning $_
            return
        }

        throw
    }
}

# Ensure NuGet provider is installed
Write-Output "Installing PackageProvider NuGet"
$null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue

# Ensure PSGallery repository is registered and available
if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
    Write-Output "Registering PSGallery repository"
    Register-PSRepository -Default -ErrorAction SilentlyContinue
}

# Set PSGallery to Trusted to avoid prompts in CI
$psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if ($psGallery -and $psGallery.InstallationPolicy -ne 'Trusted') {
    Write-Output "Setting PSGallery to Trusted"
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

# Update PowerShellGet if needed
if ((Get-Module PowershellGet -ListAvailable)[0].Version -lt [version]"1.6.0") {
    Write-Output "Updating PowershellGet"
    Install-Module PowershellGet -Scope CurrentUser -Force
}

Sync-PSScriptAnalyzerSettings

Write-Output "Installing Dependencies"
Import-Module "$PSScriptRoot/BuildTools.psm1" -Force
Install-Dependency
