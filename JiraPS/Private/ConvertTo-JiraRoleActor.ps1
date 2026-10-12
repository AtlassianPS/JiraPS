function ConvertTo-JiraRoleActor {
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
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.RoleActor"

            [AtlassianPS.JiraPS.RoleActor]@{
                Id          = ConvertTo-JiraNullableInt64 $i.id
                Name        = $i.name
                DisplayName = $i.displayName
                Type        = ConvertTo-JiraEnum -Type ([AtlassianPS.JiraPS.ActorType]) -Value $i.type
                AvatarUrl   = [uri]$i.avatarUrl
                ActorUser   = ConvertTo-JiraUser -InputObject $i.actorUser
                ActorGroup  = ConvertTo-JiraGroup -InputObject $i.actorGroup
            }
        }
    }
}
