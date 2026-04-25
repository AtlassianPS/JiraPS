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
        returned. Whitespace-only input is wrapped in a single ADF paragraph
        node containing the literal text — Cloud rejects an empty ADF document
        for these fields, but the caller's intent (e.g. "set this field to a
        single space") is preserved as-is. `$null` and the empty string are
        returned verbatim because ADF text nodes cannot have empty text and
        the public cmdlets already short-circuit empty input upstream
        (`if ($Description) { ... }`).

        On Server / Data Center, the input is returned verbatim so callers
        keep the legacy plain-string / wiki-markup behaviour.

        The function also detects unambiguous Jira wiki-markup table headers
        (``||header||header||``) and emits a warning on Cloud. Markdown tables
        never use double-pipes, so this heuristic is safe; single-pipe table
        rows (``|cell|cell|``) are passed through to the Markdown -> ADF
        converter without warning.

    .PARAMETER Text
        The rich-text payload supplied by the user. The parameter is
        statically typed as `[string]`, so non-string inputs are coerced
        via `.ToString()`. Callers must not pass a pre-built ADF hashtable
        here — wrapping it again would produce nonsense (a `text` node whose
        `text` is `"System.Collections.Hashtable"`). Pass the raw Markdown /
        wiki-markup string and let this helper do the wrapping.

    .PARAMETER IsCloud
        `$true` when targeting Jira Cloud (ADF wrapping required).
        `$false` for Jira Server / Data Center (verbatim pass-through).

    .OUTPUTS
        [string] on Server / Data Center, or for `$null` / empty input on
        Cloud.

        [hashtable] on Cloud for any non-empty input — an ADF document of
        the form `@{ version = 1; type = 'doc'; content = @(...) }`.
    #>
    [CmdletBinding()]
    [OutputType([string], [hashtable])]
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

    # `$null` / empty string on Cloud: return verbatim. ADF text nodes
    # cannot have empty text, and the public cmdlets already filter empty
    # input upstream (e.g. `if ($Description) { ... }`).
    if ([string]::IsNullOrEmpty($Text)) {
        return $Text
    }

    # Whitespace-only on Cloud: trust the caller and wrap the literal
    # value in a single paragraph node. ConvertTo-AtlassianDocumentFormat
    # would otherwise return an empty ADF document for whitespace input,
    # which Cloud rejects.
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @{
            version = 1
            type    = 'doc'
            content = @(
                @{
                    type    = 'paragraph'
                    content = @(@{ type = 'text'; text = $Text })
                }
            )
        }
    }

    # Wiki-markup table headers (||header||header||) are unambiguous: a
    # double-pipe never appears in valid Markdown table syntax, so warning
    # on this pattern has no false positives. Single-pipe rows (|cell|)
    # might be either a Markdown table cell or a wiki-markup data row, so
    # we deliberately do not warn on those — the Markdown -> ADF converter
    # handles real Markdown tables correctly, and the user is the source
    # of truth for what they pasted.
    if ($Text -match '(?m)^[ \t]*\|\|[^\r\n|]+\|\|') {
        Write-Warning ("Detected Jira wiki-markup table syntax (||header||header||) in the text payload. " +
            "On Jira Cloud, JiraPS converts text from Markdown to Atlassian Document Format; " +
            "wiki-markup tables are not supported and will not render correctly. " +
            "Convert the table to Markdown (| header | header | / | --- | --- | / | cell | cell |) instead.")
    }

    return ConvertTo-AtlassianDocumentFormat -Markdown $Text
}
