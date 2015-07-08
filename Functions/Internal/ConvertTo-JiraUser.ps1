function ConvertTo-JiraUser
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [PSObject[]] $InputObject
    )

    process
    {
        foreach ($i in $InputObject)
        {
#            Write-Debug "[ConvertTo-JiraUser] Processing object: '$i'"

#            Write-Debug "[ConvertTo-JiraUser] Defining standard properties"
            $props = @{
                'Name' = $i.name;
                'DisplayName' = $i.displayName;
                'EmailAddress' = $i.emailAddress;
                'Active' = [System.Convert]::ToBoolean($i.active);
                'RestUrl' = $i.self;
                'AvatarUrl' = $i.avatarUrls;
                'TimeZone' = $i.timeZone;
            }
            
#            Write-Debug "[ConvertTo-JiraUser] Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props
            
#            Write-Debug "[ConvertTo-JiraUser] Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'PSJira.User')

#            Write-Debug "[ConvertTo-JiraUser] Inserting custom toString() method"
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Body)"
            }

#            Write-Debug "[ConvertTo-JiraUser] Outputting object"
            Write-Output $result
        }
    }

    end
    {
#        Write-Debug "[ConvertTo-JiraUser] Complete"
    }
}
