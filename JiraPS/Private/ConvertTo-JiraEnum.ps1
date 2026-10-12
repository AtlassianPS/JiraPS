function ConvertTo-JiraEnum {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory )]
        [type]
        $Type,

        [AllowNull()]
        [object]
        $Value
    )

    if ($null -eq $Value) { return $null }
    $name = [string]$Value
    switch ($Type) {
        ([AtlassianPS.JiraPS.ActorType]) { $name = $name.Replace('-', ''); break }
        ([AtlassianPS.JiraPS.FilterShareType]) {
            if ($name -eq 'projectRole') { return [AtlassianPS.JiraPS.FilterShareType]::ROLE }
            break
        }
    }
    if ([Enum]::GetNames($Type) -icontains $name) { [Enum]::Parse($Type, $name, $true) }
}
