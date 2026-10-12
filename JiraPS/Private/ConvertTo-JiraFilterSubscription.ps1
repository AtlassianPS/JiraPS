function ConvertTo-JiraFilterSubscription {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.FilterSubscription])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.FilterSubscription"

            [AtlassianPS.JiraPS.FilterSubscription]@{
                Id    = ConvertTo-JiraNullableInt64 $i.id
                User  = ConvertTo-JiraUser -InputObject $i.user
                Group = ConvertTo-JiraGroup -InputObject $i.group
            }
        }
    }
}
