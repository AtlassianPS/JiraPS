#requires -Module PowerShellGet

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$standardsVersion = '0.1.6'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath
$buildRequirementsPath = Join-Path -Path $projectRoot -ChildPath 'Tools/build.requirements.psd1'
$manifestPath = Join-Path -Path $projectRoot -ChildPath 'JiraPS/JiraPS.psd1'
$psScriptAnalyzerSettingsPath = Join-Path -Path $projectRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'

if (-not (Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue)) {
    Register-PSRepository -Default -ErrorAction Stop
}

Install-Module -Name 'AtlassianPS.Standards' `
    -RequiredVersion $standardsVersion `
    -Scope CurrentUser `
    -Repository 'PSGallery' `
    -AllowClobber `
    -Force `
    -ErrorAction Stop

Import-Module -Name 'AtlassianPS.Standards' -RequiredVersion $standardsVersion -Force -ErrorAction Stop

$null = Install-AtlassianPSDependencyRequirement `
    -BuildRequirementsPath $buildRequirementsPath `
    -ManifestPath $manifestPath `
    -ErrorAction Stop

$resolvedSettingsPath = Sync-AtlassianPSScriptAnalyzerSettings `
    -DestinationPath $psScriptAnalyzerSettingsPath `
    -ErrorAction Stop

Write-Output "Shared PSScriptAnalyzer settings synchronized to '$resolvedSettingsPath'."
