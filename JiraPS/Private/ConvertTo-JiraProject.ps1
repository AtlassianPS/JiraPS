function ConvertTo-JiraProject {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Project])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Project"

            $hash = @{
                ID             = $i.id
                Key            = $i.key
                Name           = $i.name
                Description    = $i.description
                Lead           = if ($null -ne $i.lead) { ConvertTo-JiraUser -InputObject $i.lead } else { $null }
                Roles          = if ($null -ne $i.roles) { ConvertTo-JiraUriMap -InputObject $i.roles } else { $null }
                RestUrl        = [uri]$i.self
                Style          = $i.style
                Category       = $null
                AssigneeType   = ConvertTo-JiraEnum -Type ([AtlassianPS.JiraPS.AssigneeType]) -Value $i.assigneeType
                ProjectTypeKey = $i.projectTypeKey
                Url            = [uri]$i.url
                Email          = $i.email
            }

            $category = if ($i.projectCategory) { $i.projectCategory } else { $i.Category }
            if ($category) {
                $hash.Category = [AtlassianPS.JiraPS.ProjectCategory]@{
                    Id          = $category.id
                    Name        = $category.name
                    Description = $category.description
                    RestUrl     = [uri]$category.self
                }
            }
            if ($null -ne $i.versions) { $hash.Versions = [AtlassianPS.JiraPS.Version[]]@(ConvertTo-JiraVersion $i.versions) }
            if ($null -ne $i.archived) { $hash.Archived = [System.Convert]::ToBoolean($i.archived) }
            if ($null -ne $i.simplified) { $hash.Simplified = [System.Convert]::ToBoolean($i.simplified) }
            if ($null -ne $i.isPrivate) { $hash.IsPrivate = [System.Convert]::ToBoolean($i.isPrivate) }
            if ($null -ne $i.issueTypes) { $hash.IssueTypes = [AtlassianPS.JiraPS.IssueType[]]@(ConvertTo-JiraIssueType $i.issueTypes) }
            if ($null -ne $i.components) { $hash.Components = [AtlassianPS.JiraPS.Component[]]@(ConvertTo-JiraComponent $i.components) }

            [AtlassianPS.JiraPS.Project]$hash
        }
    }
}
