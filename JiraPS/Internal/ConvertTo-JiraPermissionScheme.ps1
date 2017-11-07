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
        If ($InputObject.permissionSchemes) {
            $InputObject = $InputObject | Select-Object -ExpandProperty permissionSchemes
        }
        foreach ($i in $InputObject) {
            # Write-Debug "Processing object: '$i'"

            # Write-Debug "Defining standard properties"
            $props = @{
                'ID'   = $i.id
                'Name' = $i.Name
            }
            If ($i.permissions) {
                $permissionObject = foreach ($p in $i.permissions) {
                    $parentObject = @{
                        'ID'         = $p.id
                        'Holder'     = @{}
                        'permission' = $p.permission
                    }
                    $childObject = Foreach ($h in $p.Holder) {
                        @{
                            'type'      = $h.type
                            'parameter' = $h.parameter
                        }
                    }
                    $parentObject.Holder = $childObject
                    # Write-Debug "Inserting type name information"
                    $parentObject.PSObject.TypeNames.Insert(0, 'JiraPS.JiraPermissionSchemeProperty')
                    $parentObject

                }
                $props.PermissionScheme = $permissionObject
            }
            # Write-Debug "Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props

            If ($result.PermissionScheme) {
                # Write-Debug "[ConvertTo-JiraPermissionScheme] Inserting custom toString() method"
                $result.PermissionScheme | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                    Write-Output "JiraPS.PermissionSchemeProperty"
                }
            }

            # Write-Debug "Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.JiraPermissionScheme')

            # Write-Debug "Outputting object"
            Write-Output $result
        }
    }

    end {
        # Write-Debug "Complete"
    }
}
