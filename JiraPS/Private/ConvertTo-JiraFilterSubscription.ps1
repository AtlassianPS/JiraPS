function ConvertTo-JiraFilterSubscription {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.FilterSubscription])]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            [AtlassianPS.JiraPS.FilterSubscription]@{
                Id    = ConvertTo-JiraNullableInt64 $i.id
                User  = if ($i.user) { ConvertTo-JiraUser $i.user } else { $null }
                Group = if ($i.group) { ConvertTo-JiraGroup $i.group } else { $null }
            }
        }
    }
}
