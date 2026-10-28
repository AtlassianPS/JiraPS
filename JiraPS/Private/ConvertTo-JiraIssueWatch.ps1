function ConvertTo-JiraIssueWatch {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.IssueWatches objects.
    #>
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.IssueWatches])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.IssueWatches"

            [AtlassianPS.JiraPS.IssueWatches]@{
                Self       = [uri]$i.self
                WatchCount = ConvertTo-JiraNullableInt64 $i.watchCount
                IsWatching = $i.isWatching
                Watchers   = [AtlassianPS.JiraPS.User[]]@(ConvertTo-JiraUser $i.watchers)
            }
        }
    }
}
