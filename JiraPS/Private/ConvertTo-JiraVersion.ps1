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
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $result = [AtlassianPS.JiraPS.Version]@{
                ID          = $i.id
                Project     = $i.projectId
                Name        = $i.name
                Description = $i.description
                Archived    = $i.archived
                Released    = $i.released
                Overdue     = $i.overdue
                RestUrl     = $i.self
            }

            # Legacy contract: missing dates surface as empty string, not $null,
            # so existing user scripts that test `if ($v.StartDate)` continue
            # to short-circuit on missing values.
            if ($i.startDate) {
                $result.StartDate = Get-Date $i.startDate
            }
            else {
                $result.StartDate = ""
            }

            if ($i.releaseDate) {
                $result.ReleaseDate = Get-Date $i.releaseDate
            }
            else {
                $result.ReleaseDate = ""
            }

            Add-LegacyTypeAlias -InputObject $result -LegacyName 'JiraPS.Version'
        }
    }
}
