function ConvertTo-JiraPermissionSchema {
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
        If ($InputObject.permissionSchemas) {
            $InputObject = $InputObject | Select-Object -ExpandProperty permissionSchemas
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
                    $parentObject.PSObject.TypeNames.Insert(0, 'JiraPS.JiraPermissionSchemaProperty')
                    $permissionObject += $parentObject

                }
                $props.PermissionSchema = $permissionObject
            }
            $result = New-Object -TypeName PSObject -Property $props

            If ($result.PermissionSchema) {
                $result.PermissionSchema | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                    Write-Output "JiraPS.JiraPermissionSchemaProperty"
                }
            }
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.JiraPermissionSchema')
            Write-Output $result
        }
    }

    end {
    }
}
