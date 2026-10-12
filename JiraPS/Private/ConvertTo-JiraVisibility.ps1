function ConvertTo-JiraVisibility {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Visibility])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Visibility"

            [AtlassianPS.JiraPS.Visibility]@{
                Type       = $i.type
                Value      = $i.value
                Identifier = $i.identifier
            }
        }
    }
}
