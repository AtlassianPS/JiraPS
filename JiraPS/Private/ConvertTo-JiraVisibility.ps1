function ConvertTo-JiraVisibility {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.Visibility objects.
    #>
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
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.Visibility"

            [AtlassianPS.JiraPS.Visibility]@{
                Type       = $i.type
                Value      = $i.value
                Identifier = $i.identifier
            }
        }
    }
}
