$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$functions = Join-Path -Path $moduleRoot -ChildPath 'Public'
$internal = Join-Path -Path $moduleRoot -ChildPath 'Internal'

# Import all .ps1 files that aren't Pester tests, and export the names of each one as a module function
$items = Resolve-Path "$functions\*.ps1" | Where-Object -FilterScript { -not ($_.ProviderPath.Contains(".Tests.")) }
foreach ($i in $items)
{
    Write-Verbose "Importing file '$($i.ProviderPath)'"
    . $i.ProviderPath
}

# Same logic here, but don't export these. These functions should be private.
$items = Resolve-Path "$internal\*.ps1" | Where-Object -FilterScript { -not ($_.ProviderPath.Contains(".Tests.")) }
foreach ($i in $items)
{
    Write-Verbose "Importing file '$($i.ProviderPath)'"
    . $i.ProviderPath
}

