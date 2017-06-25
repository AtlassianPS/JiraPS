function ConvertTo-JiraTransition
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
#            Write-Debug "[ConvertTo-JiraTransition] Processing object: '$i'"

#            Write-Debug "[ConvertTo-JiraTransition] Defining standard properties"
            $props = @{
                'ID' = $i.id;
                'Name' = $i.name;
                'ResultStatus' = (ConvertTo-JiraStatus -InputObject $i.to)
            }


#            Write-Debug "[ConvertTo-JiraTransition] Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props

#            Write-Debug "[ConvertTo-JiraTransition] Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Transition')

#            Write-Debug "[ConvertTo-JiraProject] Inserting custom toString() method"
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

#            Write-Debug "[ConvertTo-JiraTransition] Outputting object"
            Write-Output $result
        }
    }

    end
    {
#        Write-Debug "[ConvertTo-JiraTransition] Complete"
    }
}


