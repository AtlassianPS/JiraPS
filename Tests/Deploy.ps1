# This script evaluates the build and deploys if applicable

# Credit to Trevor Sullivan:
# https://github.com/pcgeek86/PSNuGet/blob/master/deploy.ps1

Set-StrictMode -Off

$shouldDeploy = $false
if ($env:APPVEYOR_REPO_TAG_NAME -notmatch 'release') {
    Write-Verbose "This commit does not include the tag matching [release], so it will not be published."
} elseif ($env:APPVEYOR_REPO_BRANCH -ne 'master') {
    Write-Verbose "This commit is not to branch [master], so it will not be published."
} elseif ($PSVersionTable.PSVersion -lt '5.0.0') {
    Write-Warning "We are not running in a PowerShell 5 environment, so the module cannot be pulbished."
} else {
    $shouldDeploy = $true
}

Write-Output ("AppVeyor build folder: [{0}]" -f $env:APPVEYOR_BUILD_FOLDER)
$publishParams = @{
    Path = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath $env:ModuleName
    NuGetApiKey = $env:PSGalleryAPIKey
}
if ($env:ReleaseNotes) { $publishParams.ReleaseNotes = $env:ReleaseNotes }
if ($env:LicenseUri) { $publishParams.LicenseUri = $env:LicenseUri }
if ($env:ProjectUri) { $publishParams.ProjectUri = $env:ProjectUri }
if ($env:Tags)
{
    # Split by commas and trim whitespace from each tag
    $publishParams.Tags = $env:Tags -split ',' | where { $_ } | foreach { $_.trim() }
}

Write-Verbose "Parameters for publishing:"
foreach ($p in $publishParams.Keys)
{
    Write-Verbose "  {0}`t{1}" -f $p, $publishParams.$p
}

if ($shouldDeploy)
{
    Write-Verbose "Calling Find-Package with dummy data to download nuget-anycpu.exe"
    Find-Package -ForceBootstrap -Name zzzzzz -ErrorAction Ignore
    Write-Verbose "Publishing module"
    Publish-Module @publishParams
}