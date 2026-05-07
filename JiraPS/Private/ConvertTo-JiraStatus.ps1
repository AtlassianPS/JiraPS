function ConvertTo-JiraStatus {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Status])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Status"

            $props = @{
                'ID'          = ConvertTo-JiraNullableInt64 $i.id
                'Name'        = $i.name
                'Description' = $i.description
                'IconUrl'     = ConvertTo-JiraUriValue $i.iconUrl
                'RestUrl'     = ConvertTo-JiraUriValue $i.self
            }

            if ($i.statusCategory) {
                $props.StatusCategory = [AtlassianPS.JiraPS.StatusCategory]@{
                    ID        = ConvertTo-JiraNullableInt64 $i.statusCategory.id
                    Key       = $i.statusCategory.key
                    Name      = $i.statusCategory.name
                    ColorName = $i.statusCategory.colorName
                    RestUrl   = ConvertTo-JiraUriValue $i.statusCategory.self
                }
            }

            [AtlassianPS.JiraPS.Status]$props
        }
    }
}
