function ConvertTo-JiraFilterPermission {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $props = @{
                'ID'      = $i.id
                'Type'    = $i.type
                'Group'   = $null
                'Project' = $null
                'Role'    = $null
            }
            if ($i.group) {
                $props["Group"] = ConvertTo-JiraGroup $i.group
            }
            if ($i.project) {
                $props["Project"] = ConvertTo-JiraProject $i.project
            }
            if ($i.role) {
                $props["Role"] = ConvertTo-JiraProjectRole $i.role
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.FilterPermission')
            $result | Add-Member -MemberType ScriptMethod -Name 'ToString' -Force -Value {
                Write-Output "$($this.Id)"
            }

            Write-Output $result
        }
    }
}
