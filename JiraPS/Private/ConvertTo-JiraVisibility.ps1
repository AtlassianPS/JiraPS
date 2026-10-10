function ConvertTo-JiraVisibility {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Visibility])]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            [AtlassianPS.JiraPS.Visibility]@{
                Type       = $i.type
                Value      = $i.value
                Identifier = $i.identifier
            }
        }
    }
}
