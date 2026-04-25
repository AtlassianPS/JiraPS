function Test-JiraRichTextField {
    <#
    .SYNOPSIS
        Returns $true if the supplied JiraPS.Field describes a rich-text
        (Atlassian Document Format) field on Jira Cloud.

    .DESCRIPTION
        Cloud's REST API v3 expects rich-text fields (description,
        environment, comment, custom textarea / wiki / doc fields) to be
        sent as Atlassian Document Format (ADF). Plain single-line
        "string" fields, numeric fields, dates, etc. continue to accept
        their native JSON value.

        This helper inspects `$Field.Schema` (returned by `Get-JiraField`)
        to decide whether the value should be wrapped. It is intentionally
        conservative: when in doubt it returns `$false` so the cmdlet
        falls back to forwarding the value as-is. See the function body
        for the exact predicate set.

    .PARAMETER Field
        A single JiraPS.Field object as returned by `Get-JiraField`.
        `$null` returns `$false`.

    .OUTPUTS
        [bool]

    .EXAMPLE
        $field = Get-JiraField -Field 'description'

        # Guard with `($value -is [string])` so a caller who has already
        # built an ADF hashtable (e.g. via ConvertTo-AtlassianDocumentFormat)
        # is passed through verbatim instead of being double-wrapped — the
        # Resolve helper expects raw Markdown / wiki-markup, not a pre-built
        # document.
        if (($value -is [string]) -and (Test-JiraRichTextField -Field $field)) {
            $value = Resolve-JiraTextFieldPayload -Text $value -IsCloud $true
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [AllowNull()]
        $Field
    )

    if (-not $Field) { return $false }

    $schema = $Field.Schema

    if (-not $schema) {
        # No schema info -- fall back to known system field IDs only.
        return ($Field.Id -in @('description', 'environment'))
    }

    if ($schema.type -eq 'doc') { return $true }
    if ($schema.system -in @('description', 'environment')) { return $true }
    if ($schema.custom -eq 'com.atlassian.jira.plugin.system.customfieldtypes:textarea') { return $true }

    return $false
}
