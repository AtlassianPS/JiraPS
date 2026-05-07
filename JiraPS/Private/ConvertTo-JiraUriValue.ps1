function ConvertTo-JiraUriValue {
    [CmdletBinding()]
    [OutputType([uri])]
    param(
        [Parameter( ValueFromPipeline )]
        [AllowNull()]
        [object]
        $InputObject
    )

    process {
        if ($null -eq $InputObject) { return $null }
        if ($InputObject -is [uri]) { return $InputObject }

        $text = $InputObject.ToString()
        if ([string]::IsNullOrWhiteSpace($text)) { return $null }

        [uri]$text
    }
}
