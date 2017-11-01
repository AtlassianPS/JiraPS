function ConvertTo-JiraIssueLink {
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
                'ID'   = $i.id
                'Type' = ConvertTo-JiraIssueLinkType $i.type
            }

            if ($i.inwardIssue) {
                $props['InwardIssue'] = ConvertTo-JiraIssue $i.inwardIssue
            }

            if ($i.outwardIssue) {
                $props['OutwardIssue'] = ConvertTo-JiraIssue $i.outwardIssue
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLink')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.ID)"
            }

            Write-Output $result
        }
    }
}
