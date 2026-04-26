function ConvertTo-GetParameter {
    <#
    .SYNOPSIS
        Generate the GET parameter string for a URL from a hashtable.

    .DESCRIPTION
        Both keys and values are URL-encoded so that values containing reserved
        characters (space, '&', '=', '?', '#', '+', '%', non-ASCII, ...)
        round-trip safely through Jira's REST API. Callers should pass raw
        values; do NOT pre-encode them at the call site.
    #>
    [CmdletBinding()]
    param (
        [Parameter( Position = 0, Mandatory = $true, ValueFromPipeline = $true )]
        [hashtable]$InputObject
    )

    process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Making HTTP get parameter string out of a hashtable"
        Write-Verbose ($InputObject | Out-String)
        if ($InputObject.Count -eq 0) { return '' }

        $pairs = $InputObject.Keys.ForEach({
                $encodedKey = ConvertTo-URLEncoded "$_"
                $value = $InputObject[$_]
                if ($null -eq $value -or "$value" -eq '') {
                    "$encodedKey="
                }
                else {
                    "{0}={1}" -f $encodedKey, (ConvertTo-URLEncoded "$value")
                }
            })
        "?" + ($pairs -join "&")
    }
}
