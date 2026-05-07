function ConvertTo-JiraPriority {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Priority])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Priority"

            $props = @{
                'ID'          = ConvertTo-JiraNullableInt64 $i.id
                'Name'        = $i.name
                'Description' = $i.description
                'StatusColor' = $i.statusColor
                'IconUrl'     = ConvertTo-JiraUriValue $i.iconUrl
                'RestUrl'     = ConvertTo-JiraUriValue $i.self
            }

            [AtlassianPS.JiraPS.Priority]$props
        }
    }
}
