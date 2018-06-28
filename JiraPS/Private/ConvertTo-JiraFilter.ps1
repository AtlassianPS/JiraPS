function ConvertTo-JiraFilter {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject,

        [PSObject[]]
        $FilterPermissions
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $props = @{
                'ID'                = $i.id
                'Name'              = $i.name
                'JQL'               = $i.jql
                'RestUrl'           = $i.self
                'ViewUrl'           = $i.viewUrl
                'SearchUrl'         = $i.searchUrl
                'Favourite'         = $i.favourite
                'FilterPermissions' = @()

                'SharePermission'   = $i.sharePermissions
                'SharedUser'        = $i.sharedUsers
                'Subscription'      = $i.subscriptions
            }

            if ($FilterPermissions) {
                $props.FilterPermissions = @(ConvertTo-JiraFilterPermission ($FilterPermissions))
            }

            if ($i.description) {
                $props.Description = $i.description
            }

            if ($i.owner) {
                $props.Owner = ConvertTo-JiraUser -InputObject $i.owner
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
            $result | Add-Member -MemberType ScriptMethod -Name 'ToString' -Force -Value {
                Write-Output "$($this.Name)"
            }
            $result | Add-Member -MemberType AliasProperty -Name 'Favorite' -Value 'Favourite'

            Write-Output $result
        }
    }
}
