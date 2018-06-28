function ConvertTo-ParameterHash {
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
                $key, $value = $_.Split("=")
                $GetParameter.Add($key, $value)
            }
        }

        Write-Output $GetParameter
    }
}
