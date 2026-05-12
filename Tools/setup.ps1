#requires -Module PowerShellGet

[CmdletBinding()]
param()

$psScriptAnalyzerSettingsUri = 'https://raw.githubusercontent.com/AtlassianPS/.github/83e062b260346c4577d3b41974f0f8aafcc5e7e5/standards/PSScriptAnalyzerSettings.psd1'
$psScriptAnalyzerSettingsPath = Join-Path (Join-Path $PSScriptRoot '..') 'PSScriptAnalyzerSettings.psd1'

function Sync-PSScriptAnalyzerSetting {
    [CmdletBinding()]
    param()

    Write-Output "Syncing PSScriptAnalyzer settings from AtlassianPS/.github"

    try {
        $invokeWebRequestParams = @{
            Uri         = $psScriptAnalyzerSettingsUri
            ErrorAction = 'Stop'
        }

        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            $invokeWebRequestParams.UseBasicParsing = $true
        }

        $response = Invoke-WebRequest @invokeWebRequestParams
        $settingsContent = $response.Content

        # Persist the pinned settings locally so build/lint always use the exact same config.
        $settingsWithCrLf = $settingsContent -replace "`r?`n", "`r`n"
        [System.IO.File]::WriteAllText(
            $psScriptAnalyzerSettingsPath,
            $settingsWithCrLf,
            [System.Text.UTF8Encoding]::new($false)
        )
        Write-Output "Pinned PSScriptAnalyzer settings synchronized to '$psScriptAnalyzerSettingsPath'."
    }
    catch {
        throw "Unable to download pinned PSScriptAnalyzer settings from '$psScriptAnalyzerSettingsUri'. $($_.Exception.Message)"
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

Sync-PSScriptAnalyzerSetting

Write-Output "Installing Dependencies"
Import-Module "$PSScriptRoot/BuildTools.psm1" -Force
Install-Dependency
