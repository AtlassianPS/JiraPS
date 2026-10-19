function Resolve-JiraRequestContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Uri]
        $Uri,

        [Parameter(Mandatory)]
        [AtlassianPS.Connection]$RequestContext,

        [Hashtable]
        $GetParameter = @{},

        [Parameter(Mandatory)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $DefaultPageSize,

        [System.Management.Automation.PSCmdlet]
        $Cmdlet
    )

    $Uri = Resolve-JiraResourceUri -Uri $Uri -RequestContext $RequestContext

    $uriQuery = ConvertTo-ParameterHash -Uri $Uri
    $internalGetParameter = Join-Hashtable $uriQuery, $GetParameter

    [Uri]$resolvedUri = $Uri.GetLeftPart("Path")

    if (-not $internalGetParameter.ContainsKey("maxResults")) { $internalGetParameter["maxResults"] = $DefaultPageSize }

    if ($Cmdlet -and $Cmdlet.PagingParameters) {
        if ($Cmdlet.PagingParameters.Skip) { $internalGetParameter["startAt"] = $Cmdlet.PagingParameters.Skip }

        if ($Cmdlet.PagingParameters.First -lt $internalGetParameter["maxResults"]) {
            $internalGetParameter["maxResults"] = $Cmdlet.PagingParameters.First
        }
    }

    [Uri]$paginatedUri = "{0}{1}" -f $resolvedUri, (ConvertTo-GetParameter $internalGetParameter)

    [PSCustomObject]@{
        Uri          = $resolvedUri
        PaginatedUri = $paginatedUri
        GetParameter = $internalGetParameter
    }
}
