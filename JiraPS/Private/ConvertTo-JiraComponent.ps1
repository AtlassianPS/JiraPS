function ConvertTo-JiraComponent {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Component])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Component"

            $props = @{
                'ID'          = $i.id
                'Name'        = $i.name
                'RestUrl'     = [uri]$i.self
                'Lead'        = $null
                'ProjectName' = $i.project
                'ProjectId'   = $i.projectId
            }

            if ($i.lead) {
                $props.Lead = ConvertTo-JiraUser -InputObject $i.lead
                $props.LeadDisplayName = $i.lead.displayName
            }

            if ($i.description) { $props.Description = $i.description }
            if ($i.assigneeType) { $props.AssigneeType = $i.assigneeType }
            if ($i.realAssigneeType) { $props.RealAssigneeType = $i.realAssigneeType }
            if ($null -ne $i.isAssigneeTypeValid) { $props.IsAssigneeTypeValid = [System.Convert]::ToBoolean($i.isAssigneeTypeValid) }

            [AtlassianPS.JiraPS.Component]$props
        }
    }
}
