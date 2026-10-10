function ConvertTo-JiraIssueProgress {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.IssueProgress])]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            [AtlassianPS.JiraPS.IssueProgress]@{
                Progress = ConvertTo-JiraNullableInt64 $i.progress
                Total    = ConvertTo-JiraNullableInt64 $i.total
                Percent  = ConvertTo-JiraNullableInt64 $i.percent
            }
        }
    }
}
