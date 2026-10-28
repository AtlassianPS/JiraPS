function Get-JiraCachedResponse {
    <#
    .SYNOPSIS
        Retrieve an unexpired GET response using its complete connection and resource cache key.
    .DESCRIPTION
        The transport constructs the key before calling this helper.
        Expired entries are removed when read.
    #>
    [CmdletBinding()]
    param(
        [String]
        $CacheKey,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = "GET",

        [Switch]
        $BypassCache,

        [String]
        $CommandName = "Invoke-JiraRequest"
    )

    if (-not $CacheKey -or $Method -ne 'GET' -or $BypassCache) { return $null }

    if (-not $script:JiraCache) { $script:JiraCache = @{} }

    $cached = $script:JiraCache[$CacheKey]
    if ($cached -and (Get-Date) -lt $cached.Expiry) {
        Write-Verbose "[$CommandName] Cache hit for $CacheKey"
        return $cached
    }
    if ($cached) { $script:JiraCache.Remove($CacheKey) }

    $null
}
