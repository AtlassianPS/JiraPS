function Test-HasTypeName
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [PSObject]$InputObject
        ,
        [Parameter(Mandatory,Position=0)]
        [string]$TypeName
    )
    process {
        $InputObject.PSObject.TypeNames.Contains($TypeName)
    }
}
