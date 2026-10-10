function ConvertTo-JiraRoleActor {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.RoleActor])]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            [AtlassianPS.JiraPS.RoleActor]@{
                Id          = ConvertTo-JiraNullableInt64 $i.id
                Name        = $i.name
                DisplayName = $i.displayName
                Type        = ConvertTo-JiraEnum -Type ([AtlassianPS.JiraPS.ActorType]) -Value $i.type
                AvatarUrl   = [uri]$i.avatarUrl
                ActorUser   = if ($i.actorUser) { ConvertTo-JiraUser $i.actorUser } else { $null }
                ActorGroup  = if ($i.actorGroup) { ConvertTo-JiraGroup $i.actorGroup } else { $null }
            }
        }
    }
}
