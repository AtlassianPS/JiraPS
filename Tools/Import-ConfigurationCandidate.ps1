[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String]$PackagePath,

    [Parameter(Mandatory)]
    [ValidatePattern('^0\.\d+\.\d+-alpha\d{4}$')]
    [String]$Version,

    [Parameter(Mandatory)]
    [String]$ModuleRoot,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F]{64}$')]
    [String]$ExpectedSha256
)

$ErrorActionPreference = 'Stop'
if ((Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash -ne $ExpectedSha256) {
    throw 'Configuration candidate package hash does not match the reviewed artifact.'
}
if (Get-Module AtlassianPS.Configuration) { throw 'Provision the exact candidate in a fresh PowerShell process.' }
if ((Test-Path $ModuleRoot) -and @(Get-ChildItem -LiteralPath $ModuleRoot -Force).Count) {
    throw 'Candidate module root must be empty. Use a fresh root for each candidate.'
}

$null = New-Item -Path $ModuleRoot -ItemType Directory -Force
Expand-Archive -LiteralPath $PackagePath -DestinationPath $ModuleRoot -ErrorAction Stop
$ModuleRoot = (Resolve-Path $ModuleRoot).Path

$manifestPath = Join-Path $ModuleRoot 'AtlassianPS.Configuration/AtlassianPS.Configuration.psd1'
$data = Import-PowerShellDataFile -LiteralPath $manifestPath
$parts = $Version -split '-', 2
if ([Version]$data.ModuleVersion -ne [Version]$parts[0] -or
    [String]$data.PrivateData.PSData.Prerelease -cne $parts[1]) {
    throw 'Configuration candidate numeric version or exact alpha label does not match.'
}

$null = Install-AtlassianPSDependencyRequirement -BuildRequirementsPath (Join-Path $PSScriptRoot 'build.requirements.psd1') -ManifestPath $manifestPath -ErrorAction Stop
& (Join-Path $PSScriptRoot 'Assert-RuntimeDependency.ps1') -ManifestPath $manifestPath

$env:PSModulePath = (Resolve-Path $ModuleRoot).Path + [IO.Path]::PathSeparator + $env:PSModulePath
$env:ATLASSIANPS_CONFIGURATION_ROOT = Join-Path $ModuleRoot '.configuration'

Import-Module -Name $manifestPath -Global -ErrorAction Stop

$loaded = Get-Module AtlassianPS.Configuration
if ($loaded.ModuleBase -ne (Split-Path (Resolve-Path $manifestPath).Path -Parent) -or
    $loaded.PrivateData.PSData.Prerelease -cne $parts[1]) {
    throw 'The imported Configuration module is not the exact candidate.'
}

[PSCustomObject]@{
    Version = $Version
    Path    = $loaded.Path
    Sha256  = $ExpectedSha256
}
