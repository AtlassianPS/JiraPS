function ConvertTo-JiraComponent {
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
                'RestUrl'     = $i.self
                'Lead'        = $i.lead
                'ProjectName' = $i.project
                'ProjectId'   = $i.projectId
            }

            if ($i.lead) {
                $props.Lead = $i.lead
                $props.LeadDisplayName = $i.lead.displayName
            }
            else {
                $props.Lead = $null
                $props.LeadDisplayName = $null
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Component')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            Write-Output $result
        }
    }
}
