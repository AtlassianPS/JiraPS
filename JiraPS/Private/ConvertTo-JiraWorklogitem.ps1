function ConvertTo-JiraWorklogItem {
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
                'ID'         = $i.id
                'Visibility' = $i.visibility
                'Comment'    = $i.comment
                'RestUrl'    = $i.self
            }

            if ($i.author) {
                $props.Author = ConvertTo-JiraUser -InputObject $i.author
            }

            if ($i.updateAuthor) {
                $props.UpdateAuthor = ConvertTo-JiraUser -InputObject $i.updateAuthor
            }

            if ($i.created) {
                $props.Created = Get-Date ($i.created)
            }

            if ($i.updated) {
                $props.Updated = Get-Date ($i.updated)
            }

            if ($i.started) {
                $props.Started = Get-Date ($i.started)
            }

            if ($i.timeSpent) {
                $props.TimeSpent = $i.timeSpent
            }

            if ($i.timeSpentSeconds) {
                $props.TimeSpentSeconds = $i.timeSpentSeconds
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Worklogitem')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Id)"
            }

            Write-Output $result
        }
    }
}
