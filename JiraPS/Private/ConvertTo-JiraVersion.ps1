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
                Name        = $i.name
                Description = $i.description
                # Booleans default to $false on the class; an absent flag in the
                # payload means "not set" which the Jira REST docs spell as false.
                Archived    = if ($null -ne $i.archived) { [System.Convert]::ToBoolean($i.archived) } else { $false }
                Released    = if ($null -ne $i.released) { [System.Convert]::ToBoolean($i.released) } else { $false }
                Overdue     = if ($null -ne $i.overdue) { [System.Convert]::ToBoolean($i.overdue) } else { $false }
                RestUrl     = $i.self
                # Legacy contract: missing dates surface as empty string, not $null,
                # so existing user scripts that test `if ($v.StartDate)` keep
                # short-circuiting on missing values.
                StartDate   = if ($i.startDate) { Get-Date $i.startDate } else { '' }
                ReleaseDate = if ($i.releaseDate) { Get-Date $i.releaseDate } else { '' }
            }

            if ($null -ne $i.projectId) {
                $hash.Project = [long]$i.projectId
            }

            [AtlassianPS.JiraPS.Version]$hash
        }
    }
}
