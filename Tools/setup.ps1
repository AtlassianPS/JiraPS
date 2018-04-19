# PowerShell 5.1 and bellow need the PSGallery to be intialized
if ($PSVersionTable.PSVersion.Major -le 5) {
    if ($PSVersionTable.PSVersion.Major -in @(3, 4)) {
        # If PowerShellGet is not available (PSv4 and PSv3), it must be installed
        if (-not (Get-Module PowerShellGet -ListAvailable)) {
            Write-Host "Installing PowershellGet"
            Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList "/qb /i $(Join-Path $PSScriptRoot "PackageManagement_x64.msi")" -Wait
        }
    }

    if ("PSGallery" -notin (Get-PSRepository).Name) {
        Write-Host "Installing PackageProvider NuGet"
        # Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
        $null = Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
    }
}

# Make PSGallery trusted, to aviod a confirmation in the console
Write-Host "Trusting PSGallery"
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction Stop

$ismoProp = @{
    Scope       = "CurrentUser"
    ErrorAction = "Stop"
    Force       = $true
    Verbose     = $true
}

Write-Host "Installing InvokeBuild"
Install-Module "InvokeBuild" @ismoProp

$buildHelpersConditions = @{}
if ($PSVersionTable.PSVersion.Major -ge 5) {
    # PSv4 does not have the `-AllowClobber` parameter
    $buildHelpersConditions["AllowClobber"] = $true
}
Write-Host "Installing BuildHelpers"
Install-Module "BuildHelpers" @ismoProp @buildHelpersConditions

$pesterConditions = @{}
if ($PSVersionTable.PSVersion.Major -ge 5) {
    # PSv4 does not have the `-SkipPublisherCheck` parameter
    $pesterConditions["SkipPublisherCheck"] = $true
}
Write-Host "Installing Pester"
Install-Module "Pester" @ismoProp -RequiredVersion "4.1.1" @pesterConditions

Write-Host "Installing platyPS"
Install-Module "platyPS" @ismoProp -RequiredVersion "0.1.0.200"

Write-Host "Installing PSScriptAnalyzer"
Install-Module "PSScriptAnalyzer" @ismoProp
