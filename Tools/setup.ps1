[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
param()

# If PowerShellGet is not available (PSv4 and PSv3), it must be installed
if ($PSVersionTable.PSVersion.Major -in @(3, 4)) {
    if (-not (Get-Module PowerShellGet -ListAvailable)) {
        Write-Host "Installing PowershellGet"
        Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList "/qn /quiet /i $(Join-Path $PSScriptRoot "PackageManagement_x64.msi")" -Wait
        $null = Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue
    }
}

# Fail if PowerShellGet could not be found
Import-Module PowerShellGet -ErrorAction SilentlyContinue
if (-not (Get-Module PowerShellGet)) {
    throw "PowerShellGet still not available"
}

# PowerShell 5.1 and bellow need the PSGallery to be intialized
if (-not ($gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
    Write-Host "Installing PackageProvider NuGet"
    $null = Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue
}

# Make PSGallery trusted, to aviod a confirmation in the console
if (-not ($gallery.Trusted)) {
    Write-Host "Trusting PSGallery"
    # Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
}

Write-Host "Installing PSDepend"
Install-Module PSDepend -Scope CurrentUser -Force
Write-Host "Installing InvokeBuild"
Install-Module InvokeBuild -Scope CurrentUser -Force

Write-Host "Installing Dependencies"
Invoke-Build -Task InstallDependencies
