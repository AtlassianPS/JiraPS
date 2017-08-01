function ConvertTo-JiraVersion {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true
        )]
        [PSObject[]] $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            # Write-Debug "Processing object: '$i'"

            # Write-Debug "Defining standard properties"
            $props = @{
                'ID'          = $i.id;
                'ProjectID'   = $i.projectId;
                'Name'        = $i.name;
                'Description' = $i.description;
                'Archived'    = $i.archived;
                'Released'    = $i.released;
                'Overdue'     = $i.overdue;
                'RestUrl'     = $i.self;
            }
            if ($i.releaseDate) { $props["ReleaseDate"] = (Get-Date $i.releaseDate) }
            if ($i.userReleaseDate) { $props["UserReleaseDate"] = (Get-Date $i.userReleaseDate) }

            # Write-Debug "Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props

            # Write-Debug "Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Version')

            # Write-Debug "[ConvertTo-JiraProject] Inserting custom toString() method"
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            # Write-Debug "Outputting object"
            Write-Output $result
        }
    }

    end {
        # Write-Debug "Complete"
    }
}
