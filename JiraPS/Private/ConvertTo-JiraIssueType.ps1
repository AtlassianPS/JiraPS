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
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.IssueType"

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
            if ($i.scope) {
                $props.Scope = [AtlassianPS.JiraPS.IssueTypeScope]@{
                    Type    = $i.scope.type
                    Project = if ($null -ne $i.scope.project) { ConvertTo-JiraProject -InputObject $i.scope.project } else { $null }
                }
            }

            [AtlassianPS.JiraPS.IssueType]$props
        }
    }
}
