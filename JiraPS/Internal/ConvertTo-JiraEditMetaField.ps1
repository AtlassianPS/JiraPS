function ConvertTo-JiraEditMetaField {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [PSObject[]] $InputObject,

        [Switch] $ReturnError
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[ConvertTo-JiraEditMetaField] Processing object: '$i'"

            if ($i.errorMessages) {
                # Write-Debug "[ConvertTo-JiraEditMetaField] Detected an errorMessages property. This is an error result."

                if ($ReturnError) {
                    # Write-Debug "[ConvertTo-JiraEditMetaField] Outputting details about error message"
                    $props = @{
                        'ErrorMessages' = $i.errorMessages;
                    }

                    $result = New-Object -TypeName PSObject -Property $props
                    $result.PSObject.TypeNames.Insert(0, 'JiraPS.Error')

                    Write-Output $result
                }
            }
            else {
                $fields = $i.fields
                $fieldNames = (Get-Member -InputObject $fields -MemberType '*Property').Name
                foreach ($f in $fieldNames) {
                    Write-Debug "[ConvertTo-JiraEditMetaField] Processing field [$f]"
                    $item = $fields.$f

                    $props = @{
                        'Id'              = $f;
                        'Name'            = $item.name;
                        'HasDefaultValue' = [System.Convert]::ToBoolean($item.hasDefaultValue);
                        'Required'        = [System.Convert]::ToBoolean($item.required);
                        'Schema'          = $item.schema;
                        'Operations'      = $item.operations;
                    }

                    if ($item.allowedValues) {
                        # Write-Debug "[ConvertTo-JiraEditMetaField] Adding AllowedValues"
                        $props.AllowedValues = $item.allowedValues
                    }

                    if ($item.autoCompleteUrl) {
                        # Write-Debug "[ConvertTo-JiraEditMetaField] Adding AutoCompleteURL"
                        $props.AutoCompleteUrl = $item.autoCompleteUrl
                    }

                    # Write-Debug "[ConvertTo-JiraEditMetaField] Checking for any additional properties"
                    foreach ($extraProperty in (Get-Member -InputObject $item -MemberType NoteProperty).Name) {
                        # Write-Debug "[ConvertTo-JiraEditMetaField] Checking property $extraProperty"
                        if ($null -eq $props.$extraProperty) {
                            # Write-Debug "[ConvertTo-JiraEditMetaField]  - Adding property [$extraProperty]"
                            $props.$extraProperty = $item.$extraProperty
                        }
                    }

                    # Write-Debug "[ConvertTo-JiraEditMetaField] Creating PSObject out of properties"
                    $result = New-Object -TypeName PSObject -Property $props

                    # Write-Debug "[ConvertTo-JiraEditMetaField] Inserting type name information"
                    $result.PSObject.TypeNames.Insert(0, 'JiraPS.EditMetaField')

                    # Write-Debug "[ConvertTo-JiraEditMetaField] Inserting custom toString() method"
                    $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                        Write-Output "$($this.Name)"
                    }

                    # Write-Debug "[ConvertTo-JiraEditMetaField] Outputting object"
                    Write-Output $result
                }
            }
        }
    }

    end {
        # Write-Debug "[ConvertTo-JiraEditMetaField] Complete"
    }
}
