function ConvertTo-JiraComponent {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.Component objects.
    #>
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Component])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.Component"

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
            if ($i.assigneeType) {
                $props.AssigneeType = ConvertTo-JiraEnum -Type ([AtlassianPS.JiraPS.AssigneeType]) -Value $i.assigneeType
            }
            if ($i.realAssigneeType) {
                $props.RealAssigneeType = ConvertTo-JiraEnum -Type ([AtlassianPS.JiraPS.AssigneeType]) -Value $i.realAssigneeType
            }
            if ($null -ne $i.isAssigneeTypeValid) { $props.IsAssigneeTypeValid = [System.Convert]::ToBoolean($i.isAssigneeTypeValid) }

            [AtlassianPS.JiraPS.Component]$props
        }
    }
}
