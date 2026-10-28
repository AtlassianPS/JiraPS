function Resolve-JiraRequestContext {
    <#
    .SYNOPSIS
        Resolve a Jira resource and merge query values without implicit paging.
    .DESCRIPTION
        Explicit paging adds the page size and supported offset controls.
        Enhanced-search token pagination omits offset parameters.
    #>
    [CmdletBinding()]
    param(
        [Parameter( Mandatory )]
        [Uri]
        $Uri,

        [Parameter( Mandatory )]
        [AtlassianPS.Connection]
        $RequestContext,

        [Hashtable]
        $GetParameter = @{},

        [Parameter( Mandatory )]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $DefaultPageSize,

        [Switch]
        $Paging,

        [System.Management.Automation.PSCmdlet]
        $Cmdlet
    )

    $Uri = Resolve-JiraResourceUri -Uri $Uri -RequestContext $RequestContext

    $uriQuery = @{}
    $queryParts = ($Uri.Query -replace '^\?', '').Split('&') | ForEach-Object {
        if ($_ -and -not $_.Contains('=')) { "$_=" } else { $_ }
    }
    $query = [Web.HttpUtility]::ParseQueryString($queryParts -join '&')
    foreach ($key in $query.AllKeys) {
        if ([String]::IsNullOrEmpty($key)) { continue }
        $values = $query.GetValues($key)
        $uriQuery[$key] = if ($values.Count -eq 1) { $values[0] } else { $values }
    }
    $internalGetParameter = Join-Hashtable $uriQuery, $GetParameter

    [Uri]$resolvedUri = $Uri.GetLeftPart("Path")

    if ($Paging) {
        if (-not $internalGetParameter.ContainsKey('maxResults')) { $internalGetParameter['maxResults'] = $DefaultPageSize }
        $tokenPaging = $Uri.AbsolutePath -match '/rest/api/[23]/search/jql$|/rest/api/2/user/list$'
        if ($tokenPaging -and $internalGetParameter.ContainsKey('startAt')) { throw 'Enhanced-search token paging does not support startAt. Use -Skip to skip items locally.' }
        foreach ($key in @('maxResults', 'startAt')) {
            if (-not $internalGetParameter.ContainsKey($key)) { continue }
            $value = 0L
            if (-not [long]::TryParse([String]$internalGetParameter[$key], [ref]$value) -or $value -lt 0 -or ($key -eq 'maxResults' -and $value -eq 0)) {
                throw "Paging query parameter $key must be a single valid integer."
            }
        }
        if ($Cmdlet -and $Cmdlet.PagingParameters) {
            if ($Cmdlet.PagingParameters.Skip -and -not $tokenPaging) { $internalGetParameter['startAt'] = $Cmdlet.PagingParameters.Skip }
            if ($Cmdlet.PagingParameters.First -gt 0 -and $Cmdlet.PagingParameters.First -lt $internalGetParameter['maxResults'] -and -not ($tokenPaging -and $Cmdlet.PagingParameters.Skip)) {
                $internalGetParameter['maxResults'] = $Cmdlet.PagingParameters.First
            }
        }
    }

    [Uri]$paginatedUri = "{0}{1}" -f $resolvedUri, (ConvertTo-GetParameter $internalGetParameter)

    [PSCustomObject]@{
        Uri          = $resolvedUri
        PaginatedUri = $paginatedUri
        GetParameter = $internalGetParameter
    }
}
