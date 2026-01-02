function ConvertTo-JiraPriority {
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
                'ID'          = [int64]$i.id
                'Name'        = $i.name
                'Description' = $i.description
                'StatusColor' = $i.statusColor
                'IconUrl'     = $i.iconUrl
                'RestUrl'     = $i.self
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Priority')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            Write-Output $result
        }
    }
}
