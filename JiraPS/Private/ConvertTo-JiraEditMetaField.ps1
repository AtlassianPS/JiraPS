function ConvertTo-JiraEditMetaField {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.EditMetaField])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.EditMetaField"

            $fields = $i.fields
            $fieldNames = $fields.PSObject.Properties.Name
            foreach ($f in $fieldNames) {
                $item = $fields.$f

                $props = @{
                    'Id'              = $f
                    'Name'            = $item.name
                    'HasDefaultValue' = [System.Convert]::ToBoolean($item.hasDefaultValue)
                    'Required'        = [System.Convert]::ToBoolean($item.required)
                    'Schema'          = $item.schema
                    'Operations'      = $item.operations
                }

                if ($item.allowedValues) { $props.AllowedValues = $item.allowedValues }

                if ($item.autoCompleteUrl) { $props.AutoCompleteUrl = [uri]$item.autoCompleteUrl }

                $extraProperties = @{}
                # NoteProperty only: $item is a JSON-deserialized field spec
                # and its data keys are NoteProperties. Synthetic Script/
                # AliasProperty would otherwise leak into the output object.
                foreach ($extraProperty in $item.PSObject.Properties.Where({ $_.MemberType -eq 'NoteProperty' }).Name) {
                    if ($null -eq $props.$extraProperty) {
                        $extraProperties.$extraProperty = $item.$extraProperty
                    }
                }

                $result = [AtlassianPS.JiraPS.EditMetaField]$props
                foreach ($extraProperty in $extraProperties.Keys) {
                    $result | Add-Member -MemberType NoteProperty -Name $extraProperty -Value $extraProperties.$extraProperty -Force
                }

                $result
            }
        }
    }
}
