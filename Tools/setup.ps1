#requires -Module PowerShellGet

[CmdletBinding()]
param(
    [Parameter(DontShow = $true)]
    [ValidateSet('Desktop', 'Core')]
    [String]$RuntimePSEdition = $PSVersionTable.PSEdition,

    [Parameter(DontShow = $true)]
    [Switch]$ForceDesktopBootstrapRemediation,

    [String]$ConfigurationCandidatePackage,

    [String]$ConfigurationCandidateSha256,

    [String]$ConfigurationCandidateRoot
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath
$buildRequirementsPath = Join-Path -Path $projectRoot -ChildPath 'Tools/build.requirements.psd1'
$manifestPath = Join-Path -Path $projectRoot -ChildPath 'JiraPS/JiraPS.psd1'

if ($ConfigurationCandidatePackage -and (Get-Module AtlassianPS.Configuration)) {
    throw 'An explicit candidate package requires a fresh process; an already loaded runtime cannot prove the selected artifact identity.'
}

$buildRequirements = Import-PowerShellDataFile -Path $buildRequirementsPath
$standardsRequirement = $buildRequirements |
    Where-Object { $_.ModuleName -eq 'AtlassianPS.Standards' } |
    Select-Object -First 1

if (-not $standardsRequirement -or -not $standardsRequirement.RequiredVersion) {
    throw "Could not resolve AtlassianPS.Standards required version from '$buildRequirementsPath'."
}

$standardsVersion = [string] $standardsRequirement.RequiredVersion
$isWindowsPowerShell = $RuntimePSEdition -eq 'Desktop'
if ($isWindowsPowerShell) {
    $nuGetProvider = Get-PackageProvider -Name 'NuGet' -ListAvailable -ErrorAction SilentlyContinue |
        Sort-Object -Property Version -Descending |
        Select-Object -First 1

    $requiresNuGetBootstrap = (
        $ForceDesktopBootstrapRemediation -or
        (-not $nuGetProvider -or $nuGetProvider.Version -lt [Version] '2.8.5.201')
    )

    if ($requiresNuGetBootstrap) {
        Install-PackageProvider -Name 'NuGet' -MinimumVersion '2.8.5.201' -Scope CurrentUser -Force -ErrorAction Stop
    }

}

$psGalleryRepository = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
if (-not $psGalleryRepository) {
    try {
        Register-PSRepository -Default -ErrorAction Stop
    }
    catch {
        throw "PSGallery repository is unavailable. Register PSGallery or configure repository access, then rerun '$($MyInvocation.MyCommand.Path)'."
    }

    $psGalleryRepository = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
}

if (-not $psGalleryRepository) {
    throw "PSGallery repository is unavailable. Register PSGallery or configure repository access, then rerun '$($MyInvocation.MyCommand.Path)'."
}

if ($isWindowsPowerShell -and ($ForceDesktopBootstrapRemediation -or $psGalleryRepository.InstallationPolicy -ne 'Trusted')) {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop
}

Install-Module -Name 'AtlassianPS.Standards' `
    -RequiredVersion $standardsVersion `
    -Scope CurrentUser `
    -Repository 'PSGallery' `
    -AllowClobber `
    -Force `
    -ErrorAction Stop

Import-Module -Name 'AtlassianPS.Standards' -RequiredVersion $standardsVersion -Force -ErrorAction Stop

if (-not (Get-Command Save-Module).Parameters.ContainsKey('AllowPrerelease')) {
    throw 'Candidate setup requires PowerShellGet with prerelease support. Install PowerShellGet 2.2.5 and start a fresh process.'
}

$candidateVersion = (Import-PowerShellDataFile (Join-Path $PSScriptRoot 'configuration-candidate.psd1')).Version
if (-not (Get-Module AtlassianPS.Configuration)) {
    if (-not $ConfigurationCandidateRoot) {
        $ConfigurationCandidateRoot = Join-Path $projectRoot ('.tmp/candidate-modules/' + [Guid]::NewGuid().ToString())
    }
    if ($ConfigurationCandidatePackage) {
        $null = & (Join-Path $PSScriptRoot 'Import-ConfigurationCandidate.ps1') -PackagePath $ConfigurationCandidatePackage -Version $candidateVersion -ModuleRoot $ConfigurationCandidateRoot -ExpectedSha256 $ConfigurationCandidateSha256
    }
    else {
        $ConfigurationCandidateRoot = [IO.Path]::GetFullPath($ConfigurationCandidateRoot)
        $null = New-Item -Path $ConfigurationCandidateRoot -ItemType Directory -Force
        Save-Module -Name AtlassianPS.Configuration -RequiredVersion $candidateVersion -AllowPrerelease -Repository PSGallery -Path $ConfigurationCandidateRoot -ErrorAction Stop
        $env:PSModulePath = $ConfigurationCandidateRoot + [IO.Path]::PathSeparator + $env:PSModulePath
        $manifest = Join-Path $ConfigurationCandidateRoot ('AtlassianPS.Configuration/' + ($candidateVersion -split '-', 2)[0] + '/AtlassianPS.Configuration.psd1')
        $data = Import-PowerShellDataFile -LiteralPath $manifest
        if (($data.ModuleVersion + '-' + $data.PrivateData.PSData.Prerelease) -cne $candidateVersion) {
            throw 'Provisioned Configuration does not match the exact test candidate.'
        }
        $env:ATLASSIANPS_CONFIGURATION_ROOT = Join-Path $ConfigurationCandidateRoot '.configuration'
        Import-Module -Name $manifest -Global -ErrorAction Stop
    }
}
$loadedCandidate = Get-Module AtlassianPS.Configuration
if (($loadedCandidate.Version.ToString() + '-' + $loadedCandidate.PrivateData.PSData.Prerelease) -cne $candidateVersion) {
    throw 'A different Configuration candidate is already loaded. Start a fresh process with the pinned exact alpha.'
}

$null = Install-AtlassianPSDependencyRequirement `
    -BuildRequirementsPath $buildRequirementsPath `
    -ManifestPath $manifestPath `
    -ErrorAction Stop

& (Join-Path $PSScriptRoot 'Assert-RuntimeDependency.ps1') -ManifestPath $manifestPath

if ($env:GITHUB_ENV) {
    Add-Content -LiteralPath $env:GITHUB_ENV -Value ("PSModulePath=" + $env:PSModulePath) -Encoding UTF8
    Add-Content -LiteralPath $env:GITHUB_ENV -Value ("ATLASSIANPS_CONFIGURATION_ROOT=" + $env:ATLASSIANPS_CONFIGURATION_ROOT) -Encoding UTF8
}
