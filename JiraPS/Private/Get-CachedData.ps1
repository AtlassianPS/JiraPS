function Get-CachedData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [scriptblock]$FetchScript,

        [int]$ExpiryMinutes = 60,

        [switch]$Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        if (-not $script:JiraCache) {
            $script:JiraCache = @{}
        }
    }

    process {
        $server = Get-JiraConfigServer -ErrorAction SilentlyContinue
        $cacheKey = "${Key}:${server}"

        $cached = $script:JiraCache[$cacheKey]

        if (-not $Force -and $cached -and (Get-Date) -lt $cached.Expiry) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Cache hit for '$Key'"
            return $cached.Data
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Cache miss for '$Key' - fetching fresh data"

        $data = & $FetchScript

        $script:JiraCache[$cacheKey] = @{
            Data   = $data
            Expiry = (Get-Date).AddMinutes($ExpiryMinutes)
            Key    = $Key
        }

        return $data
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function complete"
    }
}
