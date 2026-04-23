function ConvertTo-JiraFilter {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Filter])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject,

        [PSObject[]]
        $FilterPermissions
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Filter"

            $hash = @{
                ID                = $i.id
                Name              = $i.name
                JQL               = $i.jql
                RestUrl           = $i.self
                ViewUrl           = $i.viewUrl
                SearchUrl         = $i.searchUrl
                Favourite         = $i.favourite
                FilterPermissions = if ($FilterPermissions) { @(ConvertTo-JiraFilterPermission ($FilterPermissions)) } else { @() }
                SharePermission   = $i.sharePermissions
                SharedUser        = $i.sharedUsers
                Subscription      = $i.subscriptions
            }

            if ($i.description) {
                $hash.Description = $i.description
            }

            if ($i.owner) {
                $hash.Owner = ConvertTo-JiraUser -InputObject $i.owner
            }

            $result = [AtlassianPS.JiraPS.Filter]$hash

            $result | Add-Member -MemberType AliasProperty -Name 'Favorite' -Value 'Favourite' -Force

            $result
        }
    }
}
