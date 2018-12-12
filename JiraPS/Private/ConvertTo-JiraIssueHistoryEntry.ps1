function ConvertTo-JiraIssueHistoryEntry {
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
                'Author'  = ConvertTo-JiraUser $i.author
                'Created' = Get-Date $i.created
                'Items'    = $i.items
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.IssueHistoryEntry')
            $result | Add-Member -MemberType ScriptMethod -Name 'ToString' -Force -Value {
                Write-Output "$($this.Id)"
            }

            Write-Output $result
        }
    }
}
