function ConvertTo-JiraField {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Field])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Field"

            $props = @{
                'ID'          = $i.id
                'Name'        = $i.name
                'Custom'      = [System.Convert]::ToBoolean($i.custom)
                'Orderable'   = [System.Convert]::ToBoolean($i.orderable)
                'Navigable'   = [System.Convert]::ToBoolean($i.navigable)
                'Searchable'  = [System.Convert]::ToBoolean($i.searchable)
                'ClauseNames' = [string[]]$i.clauseNames
                'Schema'      = if ($null -ne $i.schema) { ConvertTo-JiraFieldSchema $i.schema } else { $null }
            }

            [AtlassianPS.JiraPS.Field]$props
        }
    }
}
