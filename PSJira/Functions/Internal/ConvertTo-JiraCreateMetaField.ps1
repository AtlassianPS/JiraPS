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
#            Write-Debug "[ConvertTo-JiraCreateMetaField] Processing object: '$i'"

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
                    $result.PSObject.TypeNames.Insert(0, 'PSJira.Error')

                    Write-Output $result
                }
            } else {
#                Write-Debug "[ConvertTo-JiraCreateMetaField] Defining standard properties"
                $props = @{
                    'Name' = $i.name;
                    'HasDefaultValue' = [System.Convert]::ToBoolean($i.hasDefaultValue);
                    'Required' = [System.Convert]::ToBoolean($i.required);
                    'Schema' = $i.schema;
                    'Operations' = $i.operations;
                }

                if ($i.allowedValues)
                {
#                    Write-Debug "[ConvertTo-JiraCreateMetaField] Adding AllowedValues"
                    $props.AllowedValues = $i.allowedValues
                }

                if ($i.autoCompleteUrl)
                {
#                    Write-Debug "[ConvertTo-JiraCreateMetaField] Adding AutoCompleteURL"
                    $props.AutoCompleteUrl = $i.autoCompleteUrl
                }

#                Write-Debug "[ConvertTo-JiraCreateMetaField] Checking for any additional properties"
                foreach ($f in (Get-Member -InputObject $i -MemberType NoteProperty).Name)
                {
#                    Write-Debug "[ConvertTo-JiraCreateMetaField] Checking property $f"
                    if ($props.$f -eq $null)
                    {
#                        Write-Debug "[ConvertTo-JiraCreateMetaField]  - Adding property [$f]"
                        $props.$f = $i.$f
                    }
                }

#                Write-Debug "[ConvertTo-JiraCreateMetaField] Creating PSObject out of properties"
                $result = New-Object -TypeName PSObject -Property $props

#                Write-Debug "[ConvertTo-JiraCreateMetaField] Inserting type name information"
                $result.PSObject.TypeNames.Insert(0, 'PSJira.CreateMetaField')

#                Write-Debug "[ConvertTo-JiraCreateMetaField] Inserting custom toString() method"
                $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                    Write-Output "$($this.Name)"
                }

#                Write-Debug "[ConvertTo-JiraCreateMetaField] Outputting object"
                Write-Output $result
            }
        }
    }

    end
    {
#        Write-Debug "[ConvertTo-JiraCreateMetaField] Complete"
    }
}


