function ConvertTo-JiraVersion {
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
                'Project'     = $i.projectId
                'Name'        = $i.name
                'Description' = $i.description
                'Archived'    = $i.archived
                'Released'    = $i.released
                'Overdue'     = $i.overdue
                'RestUrl'     = $i.self
            }

            if ($i.startDate) {
                $props["StartDate"] = Get-Date $i.startDate
            }
            else {
                $props["StartDate"] = ""
            }

            if ($i.releaseDate) {
                $props["ReleaseDate"] = Get-Date $i.releaseDate
            }
            else {
                $props["ReleaseDate"] = ""
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            Write-Output $result
        }
    }
}
