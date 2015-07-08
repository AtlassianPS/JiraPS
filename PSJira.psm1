$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$paths = @(
    (Join-Path -Path $moduleRoot -ChildPath 'Functions\Internal'),
    (Join-Path -Path $moduleRoot -ChildPath 'Functions')
)

foreach ($p in $paths)
{
    $items = Resolve-Path "$p\*.ps1" | Where-Object -FilterScript { -not ($_.ProviderPath.Contains(".Tests.")) }
    foreach ($i in $items)
    {
        Write-Verbose "Importing file '$($i.ProviderPath)'"
        . $i.ProviderPath
    }
}

Update-FormatData -AppendPath (Join-Path -Path $moduleRoot -ChildPath 'PSJira.format.ps1xml')