function ConvertTo-JiraCreateMetaField {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.CreateMetaField])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($item in $InputObject) {
            if ($null -eq $item) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.CreateMetaField"

            $props = @{
                'Id'              = $item.fieldId
                'Name'            = $item.name
                'HasDefaultValue' = [System.Convert]::ToBoolean($item.hasDefaultValue)
                'Required'        = [System.Convert]::ToBoolean($item.required)
                'Schema'          = if ($null -ne $item.schema) { ConvertTo-JiraFieldSchema -InputObject $item.schema } else { $null }
                'Operations'      = [string[]]$item.operations
            }

            if ($null -ne $item.allowedValues) { $props.AllowedValues = $item.allowedValues }

            if ($item.autoCompleteUrl) { $props.AutoCompleteUrl = [uri]$item.autoCompleteUrl }

            $extraProperties = @{}
            # NoteProperty only: $item is a JSON-deserialized field spec and
            # its data keys are NoteProperties. Synthetic Script/AliasProperty
            # would otherwise leak into the output object.
            foreach ($extraProperty in $item.PSObject.Properties.Where({ $_.MemberType -eq 'NoteProperty' }).Name) {
                if (-not $props.ContainsKey($extraProperty)) { $extraProperties.$extraProperty = $item.$extraProperty }
            }

            $result = [AtlassianPS.JiraPS.CreateMetaField]$props
            foreach ($extraProperty in $extraProperties.Keys) {
                $result | Add-Member -MemberType NoteProperty -Name $extraProperty -Value $extraProperties.$extraProperty -Force
            }

            $result
        }
    }
}
