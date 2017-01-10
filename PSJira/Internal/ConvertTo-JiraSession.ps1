function ConvertTo-JiraSession
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $WebResponse,

        [Parameter(Mandatory = $true)]
        $Session,

        [Parameter(Mandatory = $true)]
        [String] $Username
    )

    process
    {
        $obj = ConvertFrom-Json2 -InputObject $WebResponse

#        Write-Debug "[ConvertTo-JiraSession] Defining standard properties"
        $props = @{
            'WebSession' = $Session;
            'JSessionID' = $obj.session.value;
            'LoginInfo' = $obj.loginInfo;
        }

        if ($Username)
        {
#            Write-Debug "[ConvertTo-JiraSession] Adding username"
            $props.Username = $Username
        }

#        Write-Debug "[ConvertTo-JiraSession] Creating PSObject out of properties"
        $result = New-Object -TypeName PSObject -Property $props

#        Write-Debug "[ConvertTo-JiraSession] Inserting type name information"
        $result.PSObject.TypeNames.Insert(0, 'PSJira.Session')

#        Write-Debug "[ConvertTo-JiraSession] Inserting custom toString() method"
        $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
            Write-Output "JiraSession[JSessionID=$($this.JSessionID)]"
        }

#        Write-Debug "[ConvertTo-JiraSession] Outputting object"
        Write-Output $result
    }
}


