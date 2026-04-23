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
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $result = [AtlassianPS.JiraPS.Project]@{
                ID          = $i.id
                Key         = $i.key
                Name        = $i.name
                Description = $i.description
                Lead        = ConvertTo-JiraUser $i.lead
                IssueTypes  = ConvertTo-JiraIssueType $i.issueTypes
                Roles       = $i.roles
                RestUrl     = $i.self
                Components  = $i.components
                Style       = $i.style
            }

            if ($i.projectCategory) {
                $result.Category = $i.projectCategory
            }
            elseif ($i.Category) {
                $result.Category = $i.Category
            }
            else {
                $result.Category = $null
            }

            Add-LegacyTypeAlias -InputObject $result -LegacyName 'JiraPS.Project'
        }
    }
}
