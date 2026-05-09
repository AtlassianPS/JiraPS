function ConvertTo-JiraNullableInt64 {
    [CmdletBinding()]
    [OutputType([System.Nullable[int64]])]
    param(
        [Parameter( ValueFromPipeline )]
        [AllowNull()]
        [object]
        $InputObject
    )

    process {
        if ($null -eq $InputObject) { return $null }

        $text = $InputObject.ToString()
        if ([string]::IsNullOrWhiteSpace($text)) { return $null }

        [int64]$InputObject
    }
}
