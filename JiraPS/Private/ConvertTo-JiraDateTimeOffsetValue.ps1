function ConvertTo-JiraDateTimeOffsetValue {
    <#
    .SYNOPSIS
        Normalizes Jira timestamp values to nullable DateTimeOffset values.

    .DESCRIPTION
        Jira timestamp fields arrive as strings with an explicit offset, while tests
        and some call paths can already supply DateTimeOffset or DateTime instances.
        This helper preserves DateTimeOffset values, casts DateTime values directly to
        avoid culture-sensitive string round-trips, and parses Jira timestamp strings
        with invariant culture so the wire offset is retained.

        Null and blank string inputs are treated as absent optional timestamp fields.
        Other input types are rejected instead of being parsed through ToString().
    #>
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

        if ($InputObject -isnot [string]) {
            throw [System.ArgumentException]::new(
                "Cannot convert value of type '$($InputObject.GetType().FullName)' to System.DateTimeOffset. Expected a DateTimeOffset, DateTime, string, or null."
            )
        }

        $text = $InputObject
        if ([string]::IsNullOrWhiteSpace($text)) { return $null }

        [DateTimeOffset]::Parse($text, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AllowWhiteSpaces)
    }
}
