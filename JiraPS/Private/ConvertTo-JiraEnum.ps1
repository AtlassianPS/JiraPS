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
        $name = switch ($name) {
            'atlassian-user-role-actor' { 'AtlassianUserRoleActor' }
            'atlassian-group-role-actor' { 'AtlassianGroupRoleActor' }
            default { $name }
        }
    }
    elseif ($Type -eq [AtlassianPS.JiraPS.FilterShareType] -and $name -eq 'projectRole') {
        $name = 'ROLE'
    }
    if ([Enum]::GetNames($Type) -icontains $name) {
        [Enum]::Parse($Type, $name, $true)
    }
}
