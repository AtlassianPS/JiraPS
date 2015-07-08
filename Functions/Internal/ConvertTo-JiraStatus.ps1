function ConvertTo-JiraStatus
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [PSObject[]] $InputObject,
        
        [ValidateScript({Test-Path $_})]
        [String] $ConfigFile
    )

    process
    {
        foreach ($i in $InputObject)
        {
#            Write-Debug "[ConvertTo-JiraStatus] Processing object: '$i'"

#            Write-Debug "[ConvertTo-JiraStatus] Defining standard properties"
            $props = @{
                'ID' = $i.id;
                'Name' = $i.name;
                'Description' = $i.description;
                'IconUrl' = $i.iconUrl;
                'RestUrl' = $i.self;
            }

            
#            Write-Debug "[ConvertTo-JiraStatus] Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props
            
#            Write-Debug "[ConvertTo-JiraStatus] Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'PSJira.Status')

#            Write-Debug "[ConvertTo-JiraStatus] Outputting object"
            Write-Output $result
        }
    }

    end
    {
#        Write-Debug "[ConvertTo-JiraStatus] Complete"
    }
}
