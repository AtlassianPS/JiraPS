#requires -modules Metadata

Import-Module $PSScriptRoot/BuildTools.psm1 -Force
Import-Module Metadata -Force

$modules = Get-Dependency
$output = "@(`n"

foreach ($module in $modules) {
    Write-Output "Checking for module: $($module.Name)"
    $source = Find-Module $module.Name -Repository PSGallery -ErrorAction SilentlyContinue

    if ($source.version -gt $module.RequiredVersion) {
        Write-Output "updating $($module.Name): v$($module.RequiredVersion) --> $($source.Version)"
        $output += "    @{ ModuleName = `"$($module.Name)`"; RequiredVersion = `"$($source.Version)`" }`n"
    }
    else {
        $output += "    @{ ModuleName = `"$($module.Name)`"; RequiredVersion = `"$($module.RequiredVersion)`" }`n"
    }
}
$output += ")`n"

Set-Content -Value $output -Path "$PSScriptRoot/build.requirements.psd1" -Force
