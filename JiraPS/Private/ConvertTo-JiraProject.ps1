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
                ID          = $i.id
                Key         = $i.key
                Name        = $i.name
                Description = $i.description
                Lead        = if ($i.lead) { ConvertTo-JiraUser $i.lead } else { $null }
                IssueTypes  = if ($i.issueTypes) { ConvertTo-JiraIssueType $i.issueTypes } else { $null }
                Roles       = $i.roles
                RestUrl     = $i.self
                Components  = $i.components
                Style       = $i.style
                Category    = if ($i.projectCategory) { $i.projectCategory } elseif ($i.Category) { $i.Category } else { $null }
            }

            [AtlassianPS.JiraPS.Project]$hash
        }
    }
}
