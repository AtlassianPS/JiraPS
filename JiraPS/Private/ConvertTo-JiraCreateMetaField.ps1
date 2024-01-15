function ConvertTo-JiraCreateMetaField {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject.values) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $item = $i

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

            foreach ($extraProperty in (Get-Member -InputObject $item -MemberType NoteProperty).Name) {
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
