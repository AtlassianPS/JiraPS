function ConvertTo-JiraFieldSchema {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.FieldSchema])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.FieldSchema"

            $configuration = $null
            if ($null -ne $i.configuration) {
                $configuration = [System.Collections.Generic.Dictionary[string, object]]::new()
                if ($i.configuration -is [System.Collections.IDictionary]) {
                    foreach ($key in $i.configuration.Keys) {
                        $configuration[$key] = $i.configuration[$key]
                    }
                }
                else {
                    foreach ($property in $i.configuration.PSObject.Properties) {
                        $configuration[$property.Name] = $property.Value
                    }
                }
            }
            [AtlassianPS.JiraPS.FieldSchema]@{
                Type          = $i.type
                Items         = $i.items
                System        = $i.system
                Custom        = $i.custom
                CustomId      = ConvertTo-JiraNullableInt64 $i.customId
                Configuration = $configuration
            }
        }
    }
}
