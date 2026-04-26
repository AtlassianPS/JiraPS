$script:AlwaysSuppressedResponseHeaders = @(
    'Set-Cookie'
    'Set-Cookie2'
    'Authorization'
    'Proxy-Authorization'
)

function Write-JiraResponseHeaderLog {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [PSObject]
        $InputObject
    )

    if (-not $InputObject -or -not $InputObject.Headers) {
        return
    }

    $config = $script:JiraResponseHeaderLogConfiguration
    if (-not $config) {
        return
    }

    $matched = @{}
    foreach ($key in @($InputObject.Headers.Keys)) {
        if ($key -in $script:AlwaysSuppressedResponseHeaders) { continue }
        if (-not (& $config.Match $key)) { continue }

        $value = $InputObject.Headers[$key]
        if ($value -is [System.Collections.IEnumerable] -and $value -isnot [String]) {
            $value = ($value | ForEach-Object { [String]$_ }) -join ', '
        }

        $matched[$key] = $value
    }

    Write-DebugMessage ($matched | Out-String)
}
