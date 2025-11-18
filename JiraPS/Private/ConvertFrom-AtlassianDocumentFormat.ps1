function ConvertFrom-AtlassianDocumentFormat {
    <#
    .SYNOPSIS
    Converts Atlassian Document Format (ADF) to plain text

    .DESCRIPTION
    Jira Cloud API v3 returns description, comments, and many custom fields in ADF format.
    This function recursively extracts all text content and converts it to plain text,
    maintaining backward compatibility with API v2 behavior.

    .PARAMETER InputObject
    The ADF object (from API v3 responses)

    .EXAMPLE
    $plainText = ConvertFrom-AtlassianDocumentFormat -InputObject $issue.fields.description

    .NOTES
    This function is used internally by ConvertTo-JiraIssue and ConvertTo-JiraComment
    to maintain API v2 compatibility when using API v3.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [Object]$InputObject
    )

    process {
        # Handle null or empty
        if (-not $InputObject) {
            return ""
        }

        # If it's already a string, return it (API v2 compatibility)
        if ($InputObject -is [string]) {
            return $InputObject
        }

        # Check if this is ADF format (has type and version properties)
        if (-not ($InputObject.PSObject.Properties['type'] -and $InputObject.type -eq 'doc')) {
            # Not ADF format, try converting to string
            if ($InputObject.ToString() -ne 'System.Management.Automation.PSCustomObject') {
                return $InputObject.ToString()
            }
            return ""
        }

        $text = New-Object System.Text.StringBuilder

        function Extract-Text {
            param($node)

            if (-not $node) { return }

            # If node has text property, add it
            if ($node.PSObject.Properties['text']) {
                [void]$text.Append($node.text)
            }

            # Handle marks (bold, italic, code, etc.)
            # We ignore formatting and just extract text

            # Process content array recursively
            if ($node.PSObject.Properties['content']) {
                $isFirstChild = $true
                foreach ($child in $node.content) {
                    # Add newline before list items (except first)
                    if ($child.type -eq 'listItem' -and -not $isFirstChild) {
                        [void]$text.AppendLine()
                    }

                    # Add bullet for list items
                    if ($child.type -eq 'listItem') {
                        [void]$text.Append("• ")
                    }

                    Extract-Text $child

                    # Add newline after block elements
                    if ($child.type -in @('paragraph', 'heading', 'codeBlock', 'bulletList', 'orderedList', 'table')) {
                        [void]$text.AppendLine()
                    }

                    $isFirstChild = $false
                }
            }

            # Handle table rows
            if ($node.type -eq 'tableRow') {
                [void]$text.Append(" | ")
            }
        }

        Extract-Text $InputObject

        return $text.ToString().Trim()
    }
}
