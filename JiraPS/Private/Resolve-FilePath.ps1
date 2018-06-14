function Resolve-FilePath {
    <#
    .SYNOPSIS
        Resolve a path to it's full path

    .DESCRIPTION
        Resolve relative paths and PSDrive paths to the full path

    .LINK
        https://github.com/pester/Pester/blob/5796c95e4d6ff5528b8e14865e3f25e40f01bd65/Functions/TestResults.ps1#L13-L27
    #>
    [CmdletBinding()]
    param(
        # Path to be resolved
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [Alias("PSPath", "LiteralPath")]
        [String]
        $Path
    )

    process {
        $folder = Split-Path -Path $Path -Parent
        $file = Split-Path -Path $Path -Leaf

        if ( -not ([String]::IsNullOrEmpty($folder))) {
            $folderResolved = Resolve-Path -Path $folder
        }
        else {
            $folderResolved = Resolve-Path -Path $ExecutionContext.SessionState.Path.CurrentFileSystemLocation
        }

        Join-Path -Path $folderResolved.ProviderPath -ChildPath $file
    }
}
