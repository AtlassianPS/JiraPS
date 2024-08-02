function ConvertTo-JiraCreateMetaField {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"


            $fieldList = $null

            If ($null -ne $i.values) {
                $fieldList = $i.values | ForEach-Object {
                    @{
                        Name = $_.fieldId
                        Value = $_
                    }
                }
            }
            Elseif ($null -ne $i.projects.issuetypes.fields) {

                $fields = $i.projects.issuetypes.fields
                $fieldNames = (Get-Member -InputObject $fields -MemberType '*Property').Name

                $fieldList = $fieldNames | ForEach-Object {
                    @{
                        Name = $_
                        Value = $fields.$_
                    }
                }
            }
            Else {
                Write-Error -Exception ([System.ArgumentException]::new("Input data does not match a known CreateMeta payload.", "InputObject"))
            }

            $FieldList | ForEach-Object {
                $item = $_.Value

                $props = @{
                    'Id'              = $_.Name
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
}
