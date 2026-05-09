function ConvertTo-JiraProjectRole {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.ProjectRole])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.ProjectRole"

            $props = @{
                'ID'          = ConvertTo-JiraNullableInt64 $i.id
                'Name'        = $i.name
                'Description' = $i.description
                'Actors'      = $i.actors
                'RestUrl'     = [uri]$i.self
            }

            [AtlassianPS.JiraPS.ProjectRole]$props
        }
    }
}
