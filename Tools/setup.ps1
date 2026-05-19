#requires -Module PowerShellGet

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath
$buildRequirementsPath = Join-Path -Path $projectRoot -ChildPath 'Tools/build.requirements.psd1'
$manifestPath = Join-Path -Path $projectRoot -ChildPath 'JiraPS/JiraPS.psd1'
$psScriptAnalyzerSettingsPath = Join-Path -Path $projectRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'

. (Join-Path -Path $PSScriptRoot -ChildPath 'SharedStandards.ps1')

$standardsVersion = Get-AtlassianPSStandardsRequiredVersion -BuildRequirementsPath $buildRequirementsPath
Import-AtlassianPSStandardsModule -RequiredVersion $standardsVersion

$null = Install-AtlassianPSDependencyRequirement `
    -BuildRequirementsPath $buildRequirementsPath `
    -ManifestPath $manifestPath `
    -ErrorAction Stop

$resolvedSettingsPath = Sync-AtlassianPSScriptAnalyzerSettings `
    -DestinationPath $psScriptAnalyzerSettingsPath `
    -ErrorAction Stop

Write-Output "Shared PSScriptAnalyzer settings synchronized to '$resolvedSettingsPath'."
