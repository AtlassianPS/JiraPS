function ConvertTo-JiraFilterPermission {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.FilterPermission objects.
    #>
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.FilterPermission])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.FilterPermission"

            $props = @{
                'ID'      = ConvertTo-JiraNullableInt64 $i.id
                'Type'    = ConvertTo-JiraEnum -Type ([AtlassianPS.JiraPS.FilterShareType]) -Value $i.type
                'Group'   = $null
                'Project' = $null
                'Role'    = $null
            }

            if ($i.user) { $props["User"] = ConvertTo-JiraUser $i.user }

            if ($i.group) { $props["Group"] = ConvertTo-JiraGroup $i.group }

            if ($i.project) { $props["Project"] = ConvertTo-JiraProject $i.project }

            if ($i.role) { $props["Role"] = ConvertTo-JiraProjectRole $i.role }

            [AtlassianPS.JiraPS.FilterPermission]$props
        }
    }
}
