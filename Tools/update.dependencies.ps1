#requires -Module PowerShellGet

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [Switch]$SkipBuildRequirement,

    [Parameter()]
    [Switch]$SkipManifestRequirement
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath
$buildRequirementsPath = Join-Path -Path $projectRoot -ChildPath 'Tools/build.requirements.psd1'
$manifestPath = Join-Path -Path $projectRoot -ChildPath 'JiraPS/JiraPS.psd1'

. (Join-Path -Path $PSScriptRoot -ChildPath 'SharedStandards.ps1')

$standardsVersion = Get-AtlassianPSStandardsRequiredVersion -BuildRequirementsPath $buildRequirementsPath
Import-AtlassianPSStandardsModule -RequiredVersion $standardsVersion

$result = Update-AtlassianPSDependencyReference `
    -BuildRequirementsPath $buildRequirementsPath `
    -ManifestPath $manifestPath `
    -SkipBuildRequirement:$SkipBuildRequirement `
    -SkipManifestRequirement:$SkipManifestRequirement `
    -ErrorAction Stop

$result
