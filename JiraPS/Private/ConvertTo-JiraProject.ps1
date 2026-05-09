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
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Project"

            $hash = @{
                ID             = $i.id
                Key            = $i.key
                Name           = $i.name
                Description    = $i.description
                Lead           = if ($i.lead) { ConvertTo-JiraUser $i.lead } else { $null }
                Roles          = $i.roles
                RestUrl        = [uri]$i.self
                Style          = $i.style
                Category       = if ($i.projectCategory) { $i.projectCategory } elseif ($i.Category) { $i.Category } else { $null }
                ProjectTypeKey = $i.projectTypeKey
                Url            = [uri]$i.url
                Email          = $i.email
            }

            if ($null -ne $i.archived) { $hash.Archived = [System.Convert]::ToBoolean($i.archived) }
            if ($null -ne $i.simplified) { $hash.Simplified = [System.Convert]::ToBoolean($i.simplified) }
            if ($null -ne $i.isPrivate) { $hash.IsPrivate = [System.Convert]::ToBoolean($i.isPrivate) }
            if ($i.issueTypes) { $hash.IssueTypes = [AtlassianPS.JiraPS.IssueType[]]@(ConvertTo-JiraIssueType $i.issueTypes) }
            if ($i.components) { $hash.Components = [AtlassianPS.JiraPS.Component[]]@(ConvertTo-JiraComponent $i.components) }

            [AtlassianPS.JiraPS.Project]$hash
        }
    }
}
