#requires -Module PowerShellGet

[CmdletBinding()]
param()

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

Write-Output "Installing Dependencies"
Import-Module "$PSScriptRoot/BuildTools.psm1" -Force
Install-Dependency
