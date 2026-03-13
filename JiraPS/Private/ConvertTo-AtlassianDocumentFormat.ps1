function ConvertTo-AtlassianDocumentFormat {
    <#
    .SYNOPSIS
    Converts plain text to Atlassian Document Format (ADF)

    .DESCRIPTION
    Jira Cloud API v3 requires text fields (description, comments, etc.) to be in
    Atlassian Document Format (ADF) instead of plain text. This function converts
    plain text strings to the ADF JSON structure.

    .PARAMETER PlainText
    The plain text string to convert to ADF format

    .EXAMPLE
    $adf = ConvertTo-AtlassianDocumentFormat -PlainText "This is a test"

    .EXAMPLE
    $adf = "Multi-line`ntext here" | ConvertTo-AtlassianDocumentFormat

    .NOTES
    This function is used internally by functions that create or update text fields
    in Jira issues (New-JiraIssue, Add-JiraIssueComment, etc.)

    The ADF format is a JSON structure that represents rich text content.
    This implementation creates simple paragraphs from plain text.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$PlainText
    )

    process {
        # Handle null or empty text
        if ([string]::IsNullOrWhiteSpace($PlainText)) {
            return @{
                version = 1
                type = "doc"
                content = @()
            }
        }

        # Split text by lines and create paragraphs
        # Preserve empty lines as empty paragraphs
        $lines = $PlainText -split "`r?`n"

        $paragraphs = @()

        foreach ($line in $lines) {
            if ([string]::IsNullOrEmpty($line)) {
                # Empty line - create empty paragraph for spacing
                $paragraphs += @{
                    type = "paragraph"
                    content = @()
                }
            }
            else {
                # Non-empty line - create paragraph with text
                $paragraphs += @{
                    type = "paragraph"
                    content = @(
                        @{
                            type = "text"
                            text = $line
                        }
                    )
                }
            }
        }

        # Return ADF document structure
        @{
            version = 1
            type = "doc"
            content = $paragraphs
        }
    }
}
