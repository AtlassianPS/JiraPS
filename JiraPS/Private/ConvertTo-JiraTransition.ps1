function ConvertTo-JiraTransition {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.Transition objects.
    #>
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Transition])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.Transition"

            $props = @{
                'ID'           = ConvertTo-JiraNullableInt64 $i.id
                'Name'         = $i.name
                'ResultStatus' = if ($null -ne $i.to) { ConvertTo-JiraStatus -InputObject $i.to } else { $null }
            }

            [AtlassianPS.JiraPS.Transition]$props
        }
    }
}
