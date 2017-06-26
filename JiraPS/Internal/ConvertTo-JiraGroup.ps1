function ConvertTo-JiraGroup {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [PSObject[]] $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            # Write-Debug "[ConvertTo-JiraGroup] Processing object: '$i'"

            # Write-Debug "[ConvertTo-JiraGroup] Defining standard properties"
            $props = @{
                'Name'    = $i.name;
                'RestUrl' = $i.self;
            }

            if ($i.users) {
                # Write-Debug "[ConvertTo-JiraGroup] Adding users"
                $props.Size = $i.users.size

                if ($i.users.items) {
                    # Write-Debug "[ConvertTo-JiraGroup] Adding each user"
                    $allUsers = New-Object -TypeName System.Collections.ArrayList
                    foreach ($user in $i.users.items) {
                        [void] $allUsers.Add( (ConvertTo-JiraUser -InputObject $user) )
                    }

                    $props.Member = ($allUsers.ToArray())
                }
            }

            # Write-Debug "[ConvertTo-JiraGroup] Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props

            # Write-Debug "[ConvertTo-JiraGroup] Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Group')

            # Write-Debug "[ConvertTo-JiraGroup] Inserting custom toString() method"
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            # Write-Debug "[ConvertTo-JiraGroup] Outputting object"
            Write-Output $result
        }
    }

    end {
        # Write-Debug "[ConvertTo-JiraGroup] Complete"
    }
}
