function ConvertTo-JiraFilter
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
#            Write-Debug '[ConvertTo-JiraFilter] Processing object [$i]'

#            Write-Debug '[ConvertTo-JiraFilter] Defining standard properties'
            $props = @{
                'ID'          = $i.id;
                'Name'        = $i.name;
                'JQL'         = $i.jql;
                'RestUrl'     = $i.self;
                'ViewUrl'     = $i.viewUrl;
                'SearchUrl'   = $i.searchUrl;
                'Favourite'   = $i.favourite;

                'SharePermission' = $i.sharePermissions;
                'SharedUser'      = $i.sharedUsers;
                'Subscription'    = $i.subscriptions;
            }

            if ($i.description)
            {
#                Write-Debug '[ConvertTo-JiraFilter] Adding Description property'
                $props.Description = $i.description;
            }

            if ($i.owner)
            {
#                Write-Debug '[ConvertTo-JiraFilter] Adding owner property'
                $props.Owner = ConvertTo-JiraUser -InputObject $i.owner
            }

#            Write-Debug '[ConvertTo-JiraFilter] Creating PSObject out of properties'
            $result = New-Object -TypeName PSObject -Property $props

#            Write-Debug '[ConvertTo-JiraFilter] Inserting type name information'
            $result.PSObject.TypeNames.Insert(0, 'PSJira.Filter')

#            Write-Debug '[ConvertTo-JiraFilter] Inserting custom toString() method'
            $result | Add-Member -MemberType ScriptMethod -Name 'ToString' -Force -Value {
                Write-Output "$($this.Name)"
            }

#            Write-Debug '[ConvertTo-JiraFilter] Adding AliasProperty for Favorite'
            $result | Add-Member -MemberType AliasProperty -Name 'Favorite' -Value 'Favourite'

#            Write-Debug '[ConvertTo-JiraFilter] Outputting object'
            Write-Output $result
        }
    }

    end
    {
#        Write-Debug '[ConvertTo-JiraFilter] Complete'
    }
}


