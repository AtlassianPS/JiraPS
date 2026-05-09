function ConvertTo-JiraTransition {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Transition])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Transition"

            $props = @{
                'ID'           = ConvertTo-JiraNullableInt64 $i.id
                'Name'         = $i.name
                'ResultStatus' = ConvertTo-JiraStatus -InputObject $i.to
            }

            [AtlassianPS.JiraPS.Transition]$props
        }
    }
}
