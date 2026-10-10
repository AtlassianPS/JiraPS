function ConvertTo-JiraIssueTimeTracking {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.IssueTimeTracking])]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
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
