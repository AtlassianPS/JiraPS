function ConvertTo-JiraEnum {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [type]$Type,
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) { return $null }
    $name = [string]$Value
    if ($Type -eq [AtlassianPS.JiraPS.ActorType]) {
        switch ($name) {
            'atlassian-user-role-actor' { return [AtlassianPS.JiraPS.ActorType]::AtlassianUserRoleActor }
            'atlassian-group-role-actor' { return [AtlassianPS.JiraPS.ActorType]::AtlassianGroupRoleActor }
        }
    }
    elseif ($Type -eq [AtlassianPS.JiraPS.FilterShareType] -and $name -eq 'projectRole') {
        return [AtlassianPS.JiraPS.FilterShareType]::ROLE
    }
    if ([Enum]::GetNames($Type) -icontains $name) {
        [Enum]::Parse($Type, $name, $true)
    }
}
