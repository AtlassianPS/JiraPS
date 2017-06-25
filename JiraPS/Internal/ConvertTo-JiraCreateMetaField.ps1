function ConvertTo-JiraCreateMetaField
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [PSObject[]] $InputObject,

        [Switch] $ReturnError
    )

    process
    {
        foreach ($i in $InputObject)
        {
            Write-Debug "[ConvertTo-JiraCreateMetaField] Processing object: '$i'"

            if ($i.errorMessages)
            {
#                Write-Debug "[ConvertTo-JiraCreateMetaField] Detected an errorMessages property. This is an error result."

                if ($ReturnError)
                {
#                    Write-Debug "[ConvertTo-JiraCreateMetaField] Outputting details about error message"
                    $props = @{
                        'ErrorMessages' = $i.errorMessages;
                    }

                    $result = New-Object -TypeName PSObject -Property $props
                    $result.PSObject.TypeNames.Insert(0, 'JiraPS.Error')

                    Write-Output $result
                }
            } else {
                $fields = $i.projects.issuetypes.fields
                $fieldNames = (Get-Member -InputObject $fields -MemberType '*Property').Name
                foreach ($f in $fieldNames)
                {
                    Write-Debug "[ConvertTo-JiraCreateMetaField] Processing field [$f]"
                    $item = $fields.$f

                    $props = @{
                        'Id' = $f;
                        'Name' = $item.name;
                        'HasDefaultValue' = [System.Convert]::ToBoolean($item.hasDefaultValue);
                        'Required' = [System.Convert]::ToBoolean($item.required);
                        'Schema' = $item.schema;
                        'Operations' = $item.operations;
                    }

                    if ($item.allowedValues)
                    {
#                        Write-Debug "[ConvertTo-JiraCreateMetaField] Adding AllowedValues"
                        $props.AllowedValues = $item.allowedValues
                    }

                    if ($item.autoCompleteUrl)
                    {
#                        Write-Debug "[ConvertTo-JiraCreateMetaField] Adding AutoCompleteURL"
                        $props.AutoCompleteUrl = $item.autoCompleteUrl
                    }

#                    Write-Debug "[ConvertTo-JiraCreateMetaField] Checking for any additional properties"
                    foreach ($extraProperty in (Get-Member -InputObject $item -MemberType NoteProperty).Name)
                    {
#                        Write-Debug "[ConvertTo-JiraCreateMetaField] Checking property $extraProperty"
                        if ($props.$extraProperty -eq $null)
                        {
#                            Write-Debug "[ConvertTo-JiraCreateMetaField]  - Adding property [$extraProperty]"
                            $props.$extraProperty = $item.$extraProperty
                        }
                    }

#                    Write-Debug "[ConvertTo-JiraCreateMetaField] Creating PSObject out of properties"
                    $result = New-Object -TypeName PSObject -Property $props

#                    Write-Debug "[ConvertTo-JiraCreateMetaField] Inserting type name information"
                    $result.PSObject.TypeNames.Insert(0, 'JiraPS.CreateMetaField')

#                    Write-Debug "[ConvertTo-JiraCreateMetaField] Inserting custom toString() method"
                    $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                        Write-Output "$($this.Name)"
                    }

#                    Write-Debug "[ConvertTo-JiraCreateMetaField] Outputting object"
                    Write-Output $result
                }
            }
        }
    }

    end
    {
#        Write-Debug "[ConvertTo-JiraCreateMetaField] Complete"
    }
}


