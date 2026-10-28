function Convert-Result {
    <#
    .SYNOPSIS
        Apply the requested private converter when available, otherwise emit the response unchanged.
    #>
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        $InputObject,

        $OutputType
    )

    process {
        $InputObject | ForEach-Object {
            $item = $_
            if ($OutputType) { $converter = "ConvertTo-$OutputType" }

            if ($converter -and (Test-Path function:\$converter)) {
                Write-DebugMessage "Outputting `$result as $OutputType"
                $item | & $converter
            }
            else {
                Write-DebugMessage "Outputting `$result"
                $item
            }
        }
    }
}
