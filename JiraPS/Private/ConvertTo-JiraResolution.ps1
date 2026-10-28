function ConvertTo-JiraResolution {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.Resolution objects.
    #>
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Resolution])]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.Resolution"

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
