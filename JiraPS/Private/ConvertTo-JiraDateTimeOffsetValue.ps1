function ConvertTo-JiraDateTimeOffsetValue {
    [CmdletBinding()]
    [OutputType([System.Nullable[DateTimeOffset]])]
    param(
        [Parameter( ValueFromPipeline )]
        [AllowNull()]
        [object]
        $InputObject
    )

    process {
        if ($null -eq $InputObject) { return $null }
        if ($InputObject -is [DateTimeOffset]) { return $InputObject }
        if ($InputObject -is [DateTime]) { return [DateTimeOffset]$InputObject }

        $text = $InputObject.ToString()
        if ([string]::IsNullOrWhiteSpace($text)) { return $null }

        [DateTimeOffset]::Parse($text, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AllowWhiteSpaces)
    }
}
