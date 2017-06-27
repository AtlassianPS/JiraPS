# This script evaluates the build and deploys if applicable

# Credit to Trevor Sullivan:
# https://github.com/pcgeek86/PSNuGet/blob/master/deploy.ps1
#
# This script uses Write-Host a bit. That's not good practice, but AppVeyor
# doesn't seem to display verbose output.

#region Functions
# Again, credit to Trevor Sullivan for this function. I'm not nearly this good
# with regular expressions!
function Update-ModuleManifest {
    [CmdletBinding()]
    param(
        [String] $Path,
        [String] $BuildNumber
    )

    if ([String]::IsNullOrEmpty($Path)) {
        $Path = Get-ChildItem -Path $env:APPVEYOR_BUILD_FOLDER -Include *.psd1
        if (!$Path) {
            throw 'Could not find a module manifest file'
        }
    }

    $ManifestContent = Get-Content -Path $Path -Raw
    $ManifestContent = $ManifestContent -replace '(?<=ModuleVersion\s+=\s+'')(?<ModuleVersion>.*)(?='')', ('${{ModuleVersion}}.{0}' -f $BuildNumber)
    Set-Content -Path $Path -Value $ManifestContent

    $ManifestContent -match '(?<=ModuleVersion\s+=\s+'')(?<ModuleVersion>.*)(?='')' | Out-Null
    Write-Host 'Module Version patched: ' -ForegroundColor Cyan -NoNewline
    Write-Host $Matches.ModuleVersion -ForegroundColor Green
}
#endregion

Set-StrictMode -Off
$ModuleRoot = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath $env:ModuleName

Write-Host
Write-Host "=== Beginning Deploy.ps1 ===" -ForegroundColor Green
Write-Host
Write-Host "AppVeyor build folder: " -ForegroundColor Cyan -NoNewline
Write-Host $env:APPVEYOR_BUILD_FOLDER -ForegroundColor Green
Write-Host "Module root folder: " -ForegroundColor Cyan -NoNewline
Write-Host $ModuleRoot -ForegroundColor Green

$shouldDeploy = $false
if ($env:APPVEYOR_PULL_REQUEST_NUMBER) {
    Write-Host "This commit is from a pull request, so it will not be published." -ForegroundColor Yellow
}
elseif ($env:APPVEYOR_REPO_BRANCH -ne 'master') {
    Write-Host "This commit is not to branch [master], so it will not be published." -ForegroundColor Yellow
    #} elseif ($env:APPVEYOR_REPO_COMMIT_MESSAGE -notmatch '\[release\]' -and $env:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED -notmatch '\[release\]') {
    #    Write-Host "This commit does not include the message " -ForegroundColor Yellow -NoNewline
    #    Write-Host "[release]" -ForegroundColor Green -NoNewline
    #    Write-Host ", so it will not be published." -ForegroundColor Yellow
}
elseif ($PSVersionTable.PSVersion -lt '5.0.0') {
    Write-Warning "We are not running in a PowerShell 5 environment, so the module cannot be pulbished."
}
else {
    $shouldDeploy = $true
}

Update-ModuleManifest -Path (Join-Path -Path $ModuleRoot -ChildPath 'JiraPS.psd1') -BuildNumber $env:APPVEYOR_BUILD_NUMBER

$publishParams = @{
    Path        = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath $env:ModuleName
    NuGetApiKey = $env:PSGalleryAPIKey
}
if ($env:ReleaseNotes) { $publishParams.ReleaseNotes = $env:ReleaseNotes }
# if ($env:LicenseUri) { $publishParams.LicenseUri = $env:LicenseUri }
# if ($env:ProjectUri) { $publishParams.ProjectUri = $env:ProjectUri }
# if ($env:Tags)
# {
#     # Split by commas and trim whitespace from each tag
#     $publishParams.Tags = $env:Tags -split ',' | where { $_ } | foreach { $_.trim() }
# }

Write-Host "Parameters for publishing:" -ForegroundColor Cyan
foreach ($p in $publishParams.Keys) {
    Write-Host "${p}: " -ForegroundColor Cyan -NoNewline
    if ($p -ne 'NuGetApiKey') {
        Write-Host $publishParams.$p -ForegroundColor Green
    }
    else {
        Write-Host "[Redacted]" -ForegroundColor Green
    }
}

if ($shouldDeploy) {
    Write-Host "Calling Find-Package with dummy data to download nuget-anycpu.exe"
    Find-Package -ForceBootstrap -Name zzzzzz -ErrorAction Ignore
    Write-Host "Publishing module to PowerShell Gallery" -BackgroundColor Blue -ForegroundColor White
    Publish-Module @publishParams
}

Write-Host
Write-Host "=== Completed Deploy.ps1 ===" -ForegroundColor Green
Write-Host
