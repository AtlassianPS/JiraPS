function ConvertTo-JiraComponent
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
                'Name' = $i.name;
                'RestUrl' = $i.self;
                'Lead' = $i.lead;
                'ProjectName' = $i.project;
                'ProjectId' = $i.projectId
            }

            if ($i.lead) {
                $props.Lead = $i.lead
                $props.LeadDisplayName = $i.lead.displayName
            }
            else {
                $props.Lead = $null
                $props.LeadDisplayName = $null
            }

#            Write-Debug "Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props

#            Write-Debug "Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'PSJira.Component')

#            Write-Debug "[ConvertTo-JiraComponent] Inserting custom toString() method"
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


   