<#
.SYNOPSIS
    Resolves the path to the JiraPS module for testing.

.DESCRIPTION
    This is a lightweight helper function that replaces the BuildHelpers dependency
    for Pester v5 tests. It determines whether tests are running against the source
    module or a built Release module and returns the appropriate manifest path.

.OUTPUTS
    [string] Path to the JiraPS module manifest (.psd1)

.EXAMPLE
    . "$PSScriptRoot/../../Tests/Helpers/Resolve-ModuleSource.ps1"
    $moduleToTest = Resolve-ModuleSource
    Import-Module $moduleToTest -Force
#>
function Resolve-ModuleSource {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    # Get the project root (2 levels up from Tests/)
    $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path

    # Check if we're running in a Release build
    if ($projectRoot -like "*Release") {
        $projectRoot = (Resolve-Path "$projectRoot/..").Path
    }

    # Default to source module
    $modulePath = Join-Path $projectRoot "JiraPS/JiraPS.psd1"

    # Check if Release build exists and prefer it
    $releasePath = Join-Path $projectRoot "Release/JiraPS/JiraPS.psd1"
    if (Test-Path $releasePath) {
        $modulePath = $releasePath
    }

    # Verify the module exists
    if (-not (Test-Path $modulePath)) {
        throw "Could not find JiraPS module at: $modulePath"
    }

    Write-Verbose "Using module at: $modulePath"
    return $modulePath
}
