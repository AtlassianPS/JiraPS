function ConvertTo-JiraProject {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
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
                'ID'             = $i.id
                'Key'            = $i.key
                'Name'           = $i.name
                'Description'    = $i.description
                'Lead'           = $i.Lead
                'IssueTypes'     = $i.issueTypes
                'AssigneeType'   = $i.assigneeType
                'Versions'       = $i.Versions
                'AvatarURLs'     = $i.AvatarURLs
                'ProjectTypeKey' = $i.ProjectTypeKey
                'Roles'          = $i.roles
                'RestUrl'        = $i.self
                'Components'     = $i.components
            }

            if ($i.projectCategory) {
                $props.Category = $i.projectCategory
            }
            elseif ($i.Category) {
                $props.Category = $i.Category
            }
            else {
                $props.Category = $null
            }

            # Write-Debug "Creating PSObject out of properties"
            $projectObj = New-Object -TypeName PSObject -Property $props

            # Write-Debug "Inserting type name information"
            $projectObj.PSObject.TypeNames.Insert(0, 'JiraPS.Project')

            # Write-Debug "[ConvertTo-JiraProject] Inserting custom toString() method"
            $projectObj | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            # Write-Debug "Outputting object"
            Write-Output $projectObj
        }
    }

    end {
        # Write-Debug "Complete"
    }
}
