#requires -Module PowerShellGet

[CmdletBinding()]
param()

# PowerShell 5.1 and bellow need the PSGallery to be initialized
if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue | Out-Null)) {
    Write-Output "Installing PackageProvider NuGet"
    $null = Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue
}

# Update PowerShellGet if needed
if ((Get-Module PowershellGet -ListAvailable)[0].Version -lt [version]"1.6.0") {
    Write-Output "Updating PowershellGet"
    Install-Module PowershellGet -Scope CurrentUser -Force
}

Write-Output "Installing Dependencies"
Import-Module "$PSScriptRoot/BuildTools.psm1" -Force
Install-Dependency
