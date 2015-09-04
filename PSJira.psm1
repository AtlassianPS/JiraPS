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

# Apparently, PowerShell only automatically loads format files from modules within PSModulePath.
# This line forces the current PowerShell session to load the module format file, even if the module is saved in an unusual location.
# If this module lives somewhere in your PSModulePath, this line is unnecessary (but it doesn't do any harm either).
Update-FormatData -AppendPath (Join-Path -Path $moduleRoot -ChildPath 'PSJira.format.ps1xml')