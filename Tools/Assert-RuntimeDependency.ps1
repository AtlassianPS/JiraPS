[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String]$ManifestPath
)

$ErrorActionPreference = 'Stop'
$data = Import-PowerShellDataFile -LiteralPath $ManifestPath
foreach ($requirement in $data.RequiredModules) {
    $specification = [Microsoft.PowerShell.Commands.ModuleSpecification]::new($requirement)
    $minimum = [Version]$requirement.ModuleVersion
    $maximumMajor = [Int]($requirement.MaximumVersion -split '\.')[0]
    $incompatible = @(
        Get-Module -Name $requirement.ModuleName -All | Where-Object {
            $_.Version -lt $minimum -or $_.Version.Major -ne $maximumMajor
        }
    )
    if ($incompatible.Count) {
        throw "An incompatible $($requirement.ModuleName) is loaded. Start a fresh process with the manifest's supported dependency range."
    }
    $compatible = @(Get-Module -ListAvailable -FullyQualifiedName $specification)
    if (-not $compatible.Count) {
        throw "No compatible $($requirement.ModuleName) is available within the manifest's supported dependency range."
    }
}
