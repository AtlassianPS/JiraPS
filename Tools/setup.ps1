# Make PSGallery trusted, to aviod a confirmation in the console
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

Install-Module "InvokeBuild" -Scope CurrentUser -Force

$buildHelpersConditions = @{}
if ($PSVersionTable.PSVersion.Major -ge 5) {
    # PSv4 does not have the `-AllowClobber` parameter
    $buildHelpersConditions["AllowClobber"] = $true
}
Install-Module "BuildHelpers" -Scope CurrentUser @buildHelpersConditions

$pesterConditions = @{
    RequiredVersion = "4.1.1"
    Force           = $true
}
if ($PSVersionTable.PSVersion.Major -ge 5) {
    # PSv4 does not have the `-SkipPublisherCheck` parameter
    $pesterConditions["SkipPublisherCheck"] = $true
}
Install-Module "Pester" -Scope CurrentUser @pesterConditions

Install-Module "platyPS" -Scope CurrentUser

Install-Module "PSScriptAnalyzer" -Scope CurrentUser
