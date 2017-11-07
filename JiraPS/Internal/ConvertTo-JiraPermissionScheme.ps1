function ConvertTo-JiraPermissionScheme {
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
        If($InputObject.permissionSchemes)
        {
            $InputObject = $InputObject | Select-Object -ExpandProperty permissionSchemes
        }
        foreach ($i in $InputObject) {
            # Write-Debug "Processing object: '$i'"

            # Write-Debug "Defining standard properties"
            $props = @{
                'ID'       = $i.id
                'Expand'   = $i.Expand
                #'Self'     = $i.self
                'Name'     = $i.Name
            }

            # Write-Debug "Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props

            # Write-Debug "Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.PermissionScheme')

            # Write-Debug "[ConvertTo-JiraPermissionScheme] Inserting custom toString() method"
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            # Write-Debug "Outputting object"
            Write-Output $result
        }
    }

    end {
        # Write-Debug "Complete"
    }
}
