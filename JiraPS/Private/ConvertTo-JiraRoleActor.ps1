function ConvertTo-JiraRoleActor {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.RoleActor objects.
    #>
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.RoleActor])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.RoleActor"

            [AtlassianPS.JiraPS.RoleActor]@{
                Id          = ConvertTo-JiraNullableInt64 $i.id
                Name        = $i.name
                DisplayName = $i.displayName
                Type        = ConvertTo-JiraEnum -Type ([AtlassianPS.JiraPS.ActorType]) -Value $i.type
                AvatarUrl   = [uri]$i.avatarUrl
                ActorUser   = if ($null -ne $i.actorUser) { ConvertTo-JiraUser -InputObject $i.actorUser } else { $null }
                ActorGroup  = if ($null -ne $i.actorGroup) { ConvertTo-JiraGroup -InputObject $i.actorGroup } else { $null }
            }
        }
    }
}
