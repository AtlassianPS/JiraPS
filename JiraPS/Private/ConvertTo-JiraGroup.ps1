function ConvertTo-JiraGroup {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Group])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Group"

            $hash = @{
                Name    = $i.name
                RestUrl = $i.self
            }

            if ($i.users) {
                if ($null -ne $i.users.size) {
                    $size = 0
                    if ([int]::TryParse([string]$i.users.size, [ref]$size)) {
                        $hash.Size = $size
                    }
                }

                if ($i.users.items) {
                    $allUsers = [System.Collections.Generic.List[AtlassianPS.JiraPS.User]]::new()
                    $i.users.items.ForEach({ $allUsers.Add((ConvertTo-JiraUser -InputObject $_)) })
                    $hash.Member = $allUsers.ToArray()
                }
            }

            [AtlassianPS.JiraPS.Group]$hash
        }
    }
}
