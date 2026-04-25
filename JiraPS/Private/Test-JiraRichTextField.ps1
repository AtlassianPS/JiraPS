function Test-JiraRichTextField {
    <#
    .SYNOPSIS
        Returns $true if the supplied JiraPS.Field describes a rich-text
        (Atlassian Document Format) field on Jira Cloud.

    .DESCRIPTION
        Cloud's REST API v3 expects rich-text fields (description,
        environment, comment, custom textarea / wiki / doc fields) to be
        sent as Atlassian Document Format (ADF) JSON documents. Plain
        single-line "string" fields, numeric fields, dates, etc. continue
        to accept their native JSON value.

        This helper inspects the field's `Schema` property (returned by
        `Get-JiraField`) to decide whether the value should be wrapped in
        ADF before being placed in a request body. It is intentionally
        conservative: when in doubt it returns $false so the cmdlet falls
        back to the original behaviour (passing the value through as-is).

        Recognised rich-text indicators:
          * `schema.type` is `doc` (the ADF marker on Cloud v3)
          * `schema.system` is `description` or `environment`
          * `schema.custom` is the built-in textarea custom field type
            (`com.atlassian.jira.plugin.system.customfieldtypes:textarea`)
          * No schema info, but `Id` is `description` or `environment`
            (defensive fallback for older field metadata)

    .PARAMETER Field
        A single JiraPS.Field object as returned by `Get-JiraField`.
        `$null` returns `$false`.

    .OUTPUTS
        [bool]

    .EXAMPLE
        $field = Get-JiraField -Field 'description'
        if (Test-JiraRichTextField -Field $field) {
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
