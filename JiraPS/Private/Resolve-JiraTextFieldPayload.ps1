function Resolve-JiraTextFieldPayload {
    <#
    .SYNOPSIS
        Builds the JSON-ready value for a Jira rich-text field (description,
        comment body, worklog comment, etc.) for either Cloud or Server / DC.

    .DESCRIPTION
        Encapsulates the decision between the Cloud (Atlassian Document Format)
        and Server / Data Center (plain string / wiki-markup) representations
        of a rich-text field.

        On Cloud, non-empty input is converted via
        ConvertTo-AtlassianDocumentFormat and the resulting hashtable is
        returned. Empty / whitespace-only input is returned verbatim — Cloud
        rejects an empty ADF document for these fields, and the existing
        cmdlets already filter empty input upstream where appropriate.

        On Server / Data Center, the input is returned verbatim so callers
        keep the legacy plain-string / wiki-markup behaviour.

        The function also detects wiki-markup tables and emits a warning on
        Cloud, since the ADF converter only understands Markdown tables.

    .OUTPUTS
        [object] — either a [hashtable] ADF document (Cloud, non-empty input),
        or the original [string] (Server / DC, or empty input on Cloud).
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string]
        $Text,

        [Parameter(Mandatory)]
        [bool]
        $IsCloud
    )

    if (-not $IsCloud) {
        return $Text
    }

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }

    # Wiki-markup tables (||header||header|| / |cell|cell|) are not Markdown
    # and will not survive the Markdown -> ADF conversion. Warn the caller
    # rather than silently emit a malformed document. See issue #602.
    if ($Text -match '(?m)^\s*\|{1,2}[^\r\n]') {
        $looksLikeMarkdownTable = $Text -match '(?m)^\s*\|[^\r\n|]+\|[\s\S]*?\r?\n\s*\|[-:\s|]+\|'
        if (-not $looksLikeMarkdownTable) {
            Write-Warning ("Detected what looks like Jira wiki-markup table syntax in the text payload. " +
                "On Jira Cloud, JiraPS converts text from Markdown to Atlassian Document Format; " +
                "wiki-markup tables are not supported and will not render correctly. " +
                "Convert the table to Markdown (| header | header |\\n| --- | --- |\\n| cell | cell |) instead.")
        }
    }

    return ConvertTo-AtlassianDocumentFormat -Markdown $Text
}
