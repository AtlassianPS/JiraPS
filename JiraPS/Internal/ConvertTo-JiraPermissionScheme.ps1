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
            $props = @{
                'ID'   = $i.id
                'Name' = $i.Name
            }
            If ($i.description) {
                $props.description = $i.description
            }
            If ($i.permissions) {
                $permissionObject = @()
                foreach ($p in $i.permissions) {
                    $parentObject = @{
                        'holder'     = @{}
                        'permission' = $p.permission
                    }
                    $childObject = Foreach ($h in $p.holder) {
                        @{
                            'type'      = $h.type
                            'parameter' = $h.parameter
                        }
                    }
                    $parentObject.Holder = $childObject
                    $parentObject.PSObject.TypeNames.Insert(0, 'JiraPS.JiraPermissionSchemeProperty')
                    $permissionObject += $parentObject

                }
                $props.PermissionScheme = $permissionObject
            }
            $result = New-Object -TypeName PSObject -Property $props

            If ($result.PermissionScheme) {
                $result.PermissionScheme | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                    Write-Output "JiraPS.JiraPermissionSchemeProperty"
                }
            }
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.JiraPermissionScheme')
            Write-Output $result
        }
    }

    end {
    }
}
