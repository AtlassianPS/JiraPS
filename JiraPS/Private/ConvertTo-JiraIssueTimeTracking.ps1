function ConvertTo-JiraIssueTimeTracking {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.IssueTimeTracking objects.
    #>
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.IssueTimeTracking])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.IssueTimeTracking"

            [AtlassianPS.JiraPS.IssueTimeTracking]@{
                OriginalEstimate         = $i.originalEstimate
                RemainingEstimate        = $i.remainingEstimate
                TimeSpent                = $i.timeSpent
                OriginalEstimateSeconds  = ConvertTo-JiraNullableInt64 $i.originalEstimateSeconds
                RemainingEstimateSeconds = ConvertTo-JiraNullableInt64 $i.remainingEstimateSeconds
                TimeSpentSeconds         = ConvertTo-JiraNullableInt64 $i.timeSpentSeconds
            }
        }
    }
}
