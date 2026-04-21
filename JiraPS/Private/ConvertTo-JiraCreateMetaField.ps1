function ConvertTo-JiraCreateMetaField {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($item in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $props = @{
                'Id'              = $item.fieldId
                'Name'            = $item.name
                'HasDefaultValue' = [System.Convert]::ToBoolean($item.hasDefaultValue)
                'Required'        = [System.Convert]::ToBoolean($item.required)
                'Schema'          = $item.schema
                'Operations'      = $item.operations
            }

            if ($item.allowedValues) {
                $props.AllowedValues = $item.allowedValues
            }

            if ($item.autoCompleteUrl) {
                $props.AutoCompleteUrl = $item.autoCompleteUrl
            }

            # NoteProperty only: $item is a JSON-deserialized field spec and
            # its data keys are NoteProperties. Synthetic Script/AliasProperty
            # would otherwise leak into the output object.
            foreach ($extraProperty in $item.PSObject.Properties.Where({ $_.MemberType -eq 'NoteProperty' }).Name) {
                if ($null -eq $props.$extraProperty) {
                    $props.$extraProperty = $item.$extraProperty
                }
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.CreateMetaField')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            Write-Output $result
        }
    }
}
