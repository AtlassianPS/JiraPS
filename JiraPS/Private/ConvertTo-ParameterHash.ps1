function ConvertTo-ParameterHash {
    <#
    .SYNOPSIS
        Parse a query string (or [Uri].Query) into a hashtable.

    .DESCRIPTION
        Inverse of `ConvertTo-GetParameter`. Splits each pair on the FIRST '='
        only, so values that legitimately contain '=' (e.g. base64 tokens,
        JQL fragments such as 'project=TEST') are preserved. Both keys and
        values are URL-decoded so the hashtable holds the raw values that
        callers originally supplied.
    #>
    [CmdletBinding( DefaultParameterSetName = 'ByString' )]
    param (
        # URI from which to use the query
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'ByUri' )]
        [Uri]
        $Uri,

        # Query string
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByString' )]
        [String]
        $Query
    )

    process {
        $GetParameter = @{}

        if ($Uri) {
            $Query = $Uri.Query
        }

        if ($Query -match "^\?.+") {
            $Query.TrimStart("?").Split("&") | ForEach-Object {
                $key, $value = $_.Split('=', 2)
                if (-not [String]::IsNullOrEmpty($key)) {
                    $decodedKey = ConvertFrom-URLEncoded $key
                    $decodedValue = if ([String]::IsNullOrEmpty($value)) { $value } else { ConvertFrom-URLEncoded $value }
                    $GetParameter[$decodedKey] = $decodedValue
                }
            }
        }

        Write-Output $GetParameter
    }
}
