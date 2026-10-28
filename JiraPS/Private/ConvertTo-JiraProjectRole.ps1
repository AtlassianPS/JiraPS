function ConvertTo-JiraProjectRole {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.ProjectRole objects.
    #>
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.ProjectRole])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.ProjectRole"

            $props = @{
                'ID'          = ConvertTo-JiraNullableInt64 $i.id
                'Name'        = $i.name
                'Description' = $i.description
                'Actors'      = [AtlassianPS.JiraPS.RoleActor[]]@(ConvertTo-JiraRoleActor $i.actors)
                'RestUrl'     = [uri]$i.self
            }

            [AtlassianPS.JiraPS.ProjectRole]$props
        }
    }
}
