function ConvertTo-Hashtable {
    <#
    .SYNOPSIS
        Converts a PSCustomObject (or any PSObject-wrapped value) to a plain
        Hashtable so a subsequent `[Class](hashtable)` cast lands cleanly on
        Windows PowerShell 5.1.

    .DESCRIPTION
        Casting a PSCustomObject directly to a custom .NET class throws
        PSInvalidCastException on Windows PowerShell 5.1, but casting from a
        Hashtable is fine. Round-tripping through this helper is the
        canonical AtlassianPS workaround (mirrors ConfluencePS's
        `ConvertTo-Hashtable`).
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSObject]
        $InputObject
    )

    process {
        $hash = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $hash[$property.Name] = $property.Value
        }
        $hash
    }
}
