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
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.Priority"

            $props = @{
                'ID'          = ConvertTo-JiraNullableInt64 $i.id
                'Name'        = $i.name
                'Description' = $i.description
                'StatusColor' = $i.statusColor
                'IconUrl'     = [uri]$i.iconUrl
                'RestUrl'     = [uri]$i.self
            }

            [AtlassianPS.JiraPS.Priority]$props
        }
    }
}
