function ConvertTo-JiraIssueType {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.IssueType])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.IssueType"

            $props = @{
                'Id'          = ConvertTo-JiraNullableInt64 $i.id
                'Name'        = $i.name
                'Description' = $i.description
                'IconUrl'     = [uri]$i.iconUrl
                'RestUrl'     = [uri]$i.self
                'Subtask'     = if ($null -ne $i.subtask) { [System.Convert]::ToBoolean($i.subtask) } else { $false }
            }

            if ($null -ne $i.avatarId) { $props.AvatarId = ConvertTo-JiraNullableInt64 $i.avatarId }
            if ($null -ne $i.hierarchyLevel) { $props.HierarchyLevel = [int]$i.hierarchyLevel }
            if ($i.scope) { $props.Scope = $i.scope }

            [AtlassianPS.JiraPS.IssueType]$props
        }
    }
}
