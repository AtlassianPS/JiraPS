function Set-JiraCachedResponse {
    <#
    .SYNOPSIS
        Store a GET response and its expiry using the transport's complete cache key.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Private helper used internally by Invoke-JiraRequest to update an in-memory cache; no interactive ShouldProcess flow is expected.'
    )]
    param(
        [String]
        $CacheKey,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = "GET",

        [Parameter( Mandatory )]
        $Response,

        [TimeSpan]
        $CacheExpiry = [TimeSpan]::FromHours(1),

        [String]
        $CommandName = "Invoke-JiraRequest"
    )

    if (-not $CacheKey -or $Method -ne 'GET') { return }

    if (-not $script:JiraCache) { $script:JiraCache = @{} }

    $script:JiraCache[$CacheKey] = @{
        Data   = $Response
        Expiry = (Get-Date).Add($CacheExpiry)
    }
    Write-Verbose "[$CommandName] Cached response for $CacheKey (expires in $CacheExpiry)"
}
