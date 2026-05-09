function ConvertTo-JiraIssueLinkType {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.IssueLinkType])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.IssueLinkType"

            $props = @{
                'ID'          = $i.id
                'Name'        = $i.name
                'InwardText'  = $i.inward
                'OutwardText' = $i.outward
                'RestUrl'     = [uri]$i.self
            }

            [AtlassianPS.JiraPS.IssueLinkType]$props
        }
    }
}
