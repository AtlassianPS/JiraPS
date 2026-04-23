function ConvertTo-JiraVersion {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Version])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Version"

            $hash = @{
                ID          = $i.id
                Project     = $i.projectId
                Name        = $i.name
                Description = $i.description
                Archived    = $i.archived
                Released    = $i.released
                Overdue     = $i.overdue
                RestUrl     = $i.self
                # Legacy contract: missing dates surface as empty string, not $null,
                # so existing user scripts that test `if ($v.StartDate)` keep
                # short-circuiting on missing values.
                StartDate   = if ($i.startDate) { Get-Date $i.startDate } else { '' }
                ReleaseDate = if ($i.releaseDate) { Get-Date $i.releaseDate } else { '' }
            }

            [AtlassianPS.JiraPS.Version]$hash
        }
    }
}
