function Get-JiraCachedResponse {
    [CmdletBinding()]
    param(
        [String]
        $CacheKey,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = "GET",

        [Switch]
        $BypassCache,

        [String]
        $CommandName = "Invoke-JiraMethod"
    )

    if (-not $CacheKey -or $Method -ne 'GET' -or $BypassCache) {
        return $null
    }

    if (-not $script:JiraCache) {
        $script:JiraCache = @{}
    }

    $cacheServer = Get-JiraConfigServer -ErrorAction SilentlyContinue
    $fullCacheKey = "${CacheKey}:${cacheServer}"
    $cached = $script:JiraCache[$fullCacheKey]
    if ($cached -and (Get-Date) -lt $cached.Expiry) {
        Write-Verbose "[$CommandName] Cache hit for $CacheKey"
        return $cached
    }

    $null
}
