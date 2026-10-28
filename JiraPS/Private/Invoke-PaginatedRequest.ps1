function Invoke-PaginatedRequest {
    <#
    .SYNOPSIS
        Emit items from supported Jira offset or GET token pagination responses.
    .DESCRIPTION
        Offset pagination applies Skip on the server.
        Enhanced-search token pagination skips items locally and follows nextPageToken in the query.
        Public commands and cached requests share this same item processing.
    #>
    [CmdletBinding(SupportsPaging)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [AtlassianPS.Connection]$RequestContext,
        [String]$CacheKey,
        [TimeSpan]$CacheExpiry = [TimeSpan]::FromHours(1),
        [Switch]$BypassCache,
        [Int]$TimeoutSec = 100,
        [Int]$_RetryCount = 0,
        [Parameter(Mandatory)]
        [Uri]$Uri,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = 'Get',
        [Object]$Body,
        [String]$ContentType,
        [Hashtable]$Headers = @{},
        [Hashtable]$GetParameter = @{},
        [Switch]$Paging,
        [Int]$PageSize = $script:DefaultPageSize,
        [String]$InFile,
        [String]$OutFile,
        [String]$OutputType,
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [Object]$Response,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )

    $parameters = @{} + $PSBoundParameters
    foreach ($key in @('Paging', 'Skip', 'IncludeTotalCount', 'First', 'Response', '_RetryCount')) { $null = $parameters.Remove($key) }
    $parameters['GetParameter'] = $GetParameter.Clone()
    $isArrayPaged = $Uri.AbsolutePath -match '/rest/api/[23]/users?/search$'
    $isCursorPaged = $Uri.AbsolutePath -match '/rest/api/2/user/list$'
    $isTokenPaged = $Response.PSObject.Properties.Name -contains 'nextPageToken' -or $Uri.AbsolutePath -match '/rest/api/[23]/search/jql$' -or $isCursorPaged
    $tokenKey = if ($isCursorPaged) { 'cursor' } else { 'nextPageToken' }
    if ($isTokenPaged -and $Method -ne 'Get') { throw 'Automatic token pagination supports GET query parameters. Manage body-based continuation explicitly.' }
    if ($isTokenPaged) { $null = $parameters.GetParameter.Remove('startAt') }
    $skipRemaining = if ($isTokenPaged) { $PSCmdlet.PagingParameters.Skip } else { 0 }
    $offset = if ($GetParameter.ContainsKey('startAt')) { [long]$GetParameter['startAt'] } else { [long]$PSCmdlet.PagingParameters.Skip }
    $emitted = 0
    $seenTokens = [Collections.Generic.HashSet[String]]::new([StringComparer]::Ordinal)
    if ($GetParameter[$tokenKey]) { $null = $seenTokens.Add([String]$GetParameter[$tokenKey]) }

    if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
        if (-not $isArrayPaged -and $null -ne $Response.total) { $PSCmdlet.PagingParameters.NewTotalCount($Response.total, 1.0) }
        else { $PSCmdlet.PagingParameters.NewTotalCount(0, 0.0) }
    }

    while ($null -ne $Response) {
        if ($isArrayPaged) { $items = @($Response) }
        else {
            $containers = @($script:PagingContainers | Where-Object { $Response.PSObject.Properties[$_] })
            if ($containers.Count -ne 1 -or ($null -ne $Response.($containers[0]) -and $Response.($containers[0]) -isnot [Array])) {
                throw 'Unsupported or ambiguous Jira paging response. Use an endpoint with a supported item array, or manage continuation explicitly.'
            }
            if (-not $isTokenPaged -and -not @('startAt', 'maxResults', 'total', 'isLast' | Where-Object { $Response.PSObject.Properties[$_] }).Count) {
                throw 'Jira did not return recognized paging metadata. Manage continuation explicitly.'
            }
            $items = @(if ($null -ne $Response.($containers[0])) { $Response.($containers[0]) })
        }
        $count = $items.Count
        if ($PSCmdlet.PagingParameters.First -eq 0 -or (-not $count -and -not $isTokenPaged)) { break }
        $pageLimit = if (-not $isArrayPaged -and $null -ne $Response.maxResults -and [int]$Response.maxResults -gt 0) { [int]$Response.maxResults }
        elseif ($GetParameter.ContainsKey('maxResults')) { [int]$GetParameter['maxResults'] }
        else { $PageSize }
        $pageStart = if (-not $isArrayPaged -and $null -ne $Response.startAt) { [long]$Response.startAt } else { $offset }

        if ($skipRemaining) {
            $skipOnPage = [Math]::Min($skipRemaining, $count)
            $items = @($items | Select-Object -Skip $skipOnPage)
            $skipRemaining -= $skipOnPage
        }
        $remaining = $PSCmdlet.PagingParameters.First - $emitted
        if ($items.Count -gt $remaining) { $items = @($items | Select-Object -First $remaining) }
        if ($items.Count) { Convert-Result -InputObject $items -OutputType $OutputType }
        $emitted += $items.Count
        if ((-not $isArrayPaged -and $Response.isLast -eq $true) -or $emitted -ge $PSCmdlet.PagingParameters.First) { break }

        if ($isTokenPaged) {
            $token = if ($isCursorPaged) { $Response.nextCursor } else { $Response.nextPageToken }
            if (-not $token) { break }
            if (-not $seenTokens.Add([String]$token)) { throw 'Jira repeated a pagination token. Stopped to avoid requesting the same page indefinitely.' }
            $parameters.GetParameter[$tokenKey] = $token
        }
        else {
            $offset = $pageStart + $count
            if (-not $isArrayPaged -and $null -ne $Response.total -and $offset -ge $Response.total) { break }
            if ($count -lt $pageLimit) { break }
            $parameters.GetParameter['startAt'] = $offset
            $remaining = $PSCmdlet.PagingParameters.First - $emitted
            if ($remaining -lt $pageLimit) { $parameters.GetParameter['maxResults'] = $remaining }
        }
        $Response = Invoke-JiraRequest @parameters
        if ($null -eq $Response) {
            Write-Warning "[$($MyInvocation.MyCommand.Name)] Received null response during pagination; stopping pagination with $emitted results collected"
        }
    }
}
