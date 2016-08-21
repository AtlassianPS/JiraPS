function ConvertTo-JiraProject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [PSObject[]] $InputObject
    )

    process
    {
        foreach ($i in $InputObject)
        {
#            Write-Debug "Processing object: '$i'"

#            Write-Debug "Defining standard properties"
            $props = @{
                'ID' = $i.id;
                'Key' = $i.key;
                'Name' = $i.name;
                'Description' = $i.description;
                'IssueTypes' = $i.issueTypes;
                'Roles' = $i.roles;
                'Category' = $i.projectCategory;
                'RestUrl' = $i.self;
            }

#            Write-Debug "Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props

#            Write-Debug "Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'PSJira.Project')

#            Write-Debug "[ConvertTo-JiraProject] Inserting custom toString() method"
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

#            Write-Debug "Outputting object"
            Write-Output $result
        }
    }

    end
    {
#        Write-Debug "Complete"
    }
}


