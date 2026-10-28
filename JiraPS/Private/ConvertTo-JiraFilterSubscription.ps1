function ConvertTo-JiraFilterSubscription {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.FilterSubscription objects.
    #>
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
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.FilterSubscription"

            [AtlassianPS.JiraPS.FilterSubscription]@{
                Id    = ConvertTo-JiraNullableInt64 $i.id
                User  = if ($null -ne $i.user) { ConvertTo-JiraUser -InputObject $i.user } else { $null }
                Group = if ($null -ne $i.group) { ConvertTo-JiraGroup -InputObject $i.group } else { $null }
            }
        }
    }
}
