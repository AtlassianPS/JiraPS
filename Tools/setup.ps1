#requires -Module PowerShellGet

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath
$buildRequirementsPath = Join-Path -Path $projectRoot -ChildPath 'Tools/build.requirements.psd1'
$manifestPath = Join-Path -Path $projectRoot -ChildPath 'JiraPS/JiraPS.psd1'
$psScriptAnalyzerSettingsPath = Join-Path -Path $projectRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'

$buildRequirements = Import-PowerShellDataFile -Path $buildRequirementsPath
$standardsRequirement = $buildRequirements |
    Where-Object { $_.ModuleName -eq 'AtlassianPS.Standards' } |
    Select-Object -First 1

if (-not $standardsRequirement -or -not $standardsRequirement.RequiredVersion) {
    throw "Could not resolve AtlassianPS.Standards required version from '$buildRequirementsPath'."
}

$standardsVersion = [string] $standardsRequirement.RequiredVersion
$expectedPSGallerySourceLocation = 'https://www.powershellgallery.com/api/v2'
$psGalleryRepository = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue

if (-not $psGalleryRepository) {
    Register-PSRepository -Default -ErrorAction Stop
    $psGalleryRepository = Get-PSRepository -Name 'PSGallery' -ErrorAction Stop
}

$actualPSGallerySourceLocation = $psGalleryRepository.SourceLocation.TrimEnd('/')
if ($actualPSGallerySourceLocation -ne $expectedPSGallerySourceLocation) {
    throw "PSGallery source location mismatch. Expected '$expectedPSGallerySourceLocation' but found '$($psGalleryRepository.SourceLocation)'."
}

$installedStandardsModule = Get-Module -Name 'AtlassianPS.Standards' -ListAvailable |
    Where-Object { $_.Version -eq ([Version] $standardsVersion) } |
    Select-Object -First 1

if (-not $installedStandardsModule) {
    Install-Module -Name 'AtlassianPS.Standards' `
        -RequiredVersion $standardsVersion `
        -Scope CurrentUser `
        -Repository 'PSGallery' `
        -AllowClobber `
        -Force `
        -ErrorAction Stop
}

Import-Module -Name 'AtlassianPS.Standards' -RequiredVersion $standardsVersion -Force -ErrorAction Stop

$null = Install-AtlassianPSDependencyRequirement `
    -BuildRequirementsPath $buildRequirementsPath `
    -ManifestPath $manifestPath `
    -ErrorAction Stop

$resolvedSettingsPath = Sync-AtlassianPSScriptAnalyzerSettings `
    -DestinationPath $psScriptAnalyzerSettingsPath `
    -ErrorAction Stop

Write-Output "Shared PSScriptAnalyzer settings synchronized to '$resolvedSettingsPath'."
