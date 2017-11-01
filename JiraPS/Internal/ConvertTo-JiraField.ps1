function ConvertTo-JiraField {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true
        )]
        [PSObject[]] $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $props = @{
                'ID'          = $i.id
                'Name'        = $i.name
                'Custom'      = [System.Convert]::ToBoolean($i.custom)
                'Orderable'   = [System.Convert]::ToBoolean($i.orderable)
                'Navigable'   = [System.Convert]::ToBoolean($i.navigable)
                'Searchable'  = [System.Convert]::ToBoolean($i.searchable)
                'ClauseNames' = $i.clauseNames
                'Schema'      = $i.schema
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            Write-Output $result
        }
    }
}
