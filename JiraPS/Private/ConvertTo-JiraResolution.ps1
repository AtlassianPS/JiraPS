function ConvertTo-JiraResolution {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Resolution])]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Resolution"

            $props = @{
                ID          = $i.id
                Name        = $i.name
                Description = $i.description
                RestUrl     = [uri]$i.self
            }

            [AtlassianPS.JiraPS.Resolution]$props
        }
    }
}
