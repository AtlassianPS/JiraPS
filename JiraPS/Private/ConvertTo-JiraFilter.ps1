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
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $result = [AtlassianPS.JiraPS.Filter]@{
                ID                = $i.id
                Name              = $i.name
                JQL               = $i.jql
                RestUrl           = $i.self
                ViewUrl           = $i.viewUrl
                SearchUrl         = $i.searchUrl
                Favourite         = $i.favourite
                FilterPermissions = @()
                SharePermission   = $i.sharePermissions
                SharedUser        = $i.sharedUsers
                Subscription      = $i.subscriptions
            }

            if ($FilterPermissions) {
                $result.FilterPermissions = @(ConvertTo-JiraFilterPermission ($FilterPermissions))
            }

            if ($i.description) {
                $result.Description = $i.description
            }

            if ($i.owner) {
                $result.Owner = ConvertTo-JiraUser -InputObject $i.owner
            }

            $result | Add-Member -MemberType AliasProperty -Name 'Favorite' -Value 'Favourite' -Force

            Add-LegacyTypeAlias -InputObject $result -LegacyName 'JiraPS.Filter'
        }
    }
}
