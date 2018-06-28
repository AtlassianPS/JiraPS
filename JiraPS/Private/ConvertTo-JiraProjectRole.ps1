function ConvertTo-JiraProjectRole {
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
                'ID'          = $i.id
                'Name'        = $i.name
                'Description' = $i.description
                'Actors'      = $i.actors
                'RestUrl'     = $i.self
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.ProjectRole')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            Write-Output $result
        }
    }
}
