function Clear-JiraCache {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('All', 'Fields', 'IssueTypes', 'Priorities', 'Statuses', 'ServerInfo')]
        [string]$Type = 'All'
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (-not $script:JiraCache) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] No cache to clear"
            return
        }

        if ($Type -eq 'All') {
            $count = $script:JiraCache.Count
            $script:JiraCache = @{}
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Cleared all $count cached items"
        }
        else {
            $keysToRemove = $script:JiraCache.Keys | Where-Object { $_ -like "${Type}:*" }
            foreach ($key in $keysToRemove) {
                $script:JiraCache.Remove($key)
            }
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Cleared $($keysToRemove.Count) cached items for type '$Type'"
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function complete"
    }
}
