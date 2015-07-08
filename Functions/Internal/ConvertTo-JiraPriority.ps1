function ConvertTo-JiraPriority
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [PSObject[]] $InputObject,
        
        [ValidateScript({Test-Path $_})]
        [String] $ConfigFile,

        [Switch] $ReturnError
    )

    process
    {
        foreach ($i in $InputObject)
        {
#            Write-Debug "[ConvertTo-JiraPriority] Processing object: '$i'"

            if ($i.errorMessages)
            {
#                Write-Debug "[ConvertTo-JiraPriority] Detected an errorMessages property. This is an error result."
                
                if ($ReturnError)
                {
#                    Write-Debug "[ConvertTo-JiraPriority] Outputting details about error message"
                    $props = @{
                        'ErrorMessages' = $i.errorMessages;
                    }

                    $result = New-Object -TypeName PSObject -Property $props
                    $result.PSObject.TypeNames.Insert(0, 'PSJira.Error')

                    Write-Output $result
                }
            } else {
                $server = ($InputObject.self -split 'rest')[0]
                $http = "${server}browse/$($i.key)"

#                Write-Debug "[ConvertTo-JiraPriority] Defining standard properties"
                $props = @{
                    'ID' = $i.id;
                    'Name' = $i.name;
                    'Description' = $i.description;
                    'StatusColor' = $i.statusColor;
                    'IconUrl' = $i.iconUrl;
                    'RestUrl' = $i.self;
                }

#                Write-Debug "[ConvertTo-JiraPriority] Creating PSObject out of properties"
                $result = New-Object -TypeName PSObject -Property $props
            
#                Write-Debug "[ConvertTo-JiraPriority] Inserting type name information"
                $result.PSObject.TypeNames.Insert(0, 'PSJira.Priority')

#                Write-Debug "[ConvertTo-JiraPriority] Outputting object"
                Write-Output $result
            }
        }
    }

    end
    {
#        Write-Debug "[ConvertTo-JiraPriority] Complete"
    }
}