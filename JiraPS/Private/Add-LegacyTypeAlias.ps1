function Add-LegacyTypeAlias {
    <#
        .SYNOPSIS
        Inserts a legacy PSTypeName onto an object so historic format-data
        selectors and consumer scripts that look for PSObject.TypeNames keep
        working after a converter switches to a strong .NET type.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object]
        $InputObject,

        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $LegacyName
    )

    process {
        if ($null -eq $InputObject) {
            return
        }

        $typeNames = $InputObject.PSObject.TypeNames
        if ($typeNames[0] -ne $LegacyName) {
            $typeNames.Insert(0, $LegacyName)
        }

        $InputObject
    }
}
