function Set-JiraCachedResponse {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Private helper used internally by Invoke-JiraMethod to update an in-memory cache; no interactive ShouldProcess flow is expected.'
    )]
    param(
        [String]
        $CacheKey,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = "GET",

        [Parameter(Mandatory)]
        $Response,

        [TimeSpan]
        $CacheExpiry = [TimeSpan]::FromHours(1),

        [String]
        $CommandName = "Invoke-JiraMethod"
    )

    if (-not $CacheKey -or $Method -ne 'GET') {
        return
    }

    if (-not $script:JiraCache) {
        $script:JiraCache = @{}
    }

    $cacheServer = Get-JiraConfigServer -ErrorAction SilentlyContinue
    $fullCacheKey = "${CacheKey}:${cacheServer}"
    $script:JiraCache[$fullCacheKey] = @{
        Data   = $Response
        Expiry = (Get-Date).Add($CacheExpiry)
    }
    Write-Verbose "[$CommandName] Cached response for $CacheKey (expires in $CacheExpiry)"
}
