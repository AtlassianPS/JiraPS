function ConvertTo-JiraFilter {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.Filter objects.
    #>
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
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.Filter"

            $hash = @{
                ID              = $i.id
                Name            = $i.name
                JQL             = $i.jql
                RestUrl         = if ($i.self) { [uri]$i.self } else { [uri]$i.RestUrl }
                ViewUrl         = [uri]$i.viewUrl
                SearchUrl       = [uri]$i.searchUrl
                Favourite       = if ($null -ne $i.favourite) { [System.Convert]::ToBoolean($i.favourite) }
                else { $false }
                SharePermission = [AtlassianPS.JiraPS.FilterPermission[]]@()
                SharedUser      = $null
                Subscription    = $null
            }

            if ($i -is [AtlassianPS.JiraPS.Filter]) {
                $hash.SharePermission = $i.SharePermission
                $hash.SharedUser = $i.SharedUser
                $hash.Subscription = $i.Subscription
            }
            else {
                $hash.SharePermission = [AtlassianPS.JiraPS.FilterPermission[]]@(ConvertTo-JiraFilterPermission -InputObject $i.sharePermissions)
            }
            if ($null -ne $i.sharedUsers) {
                $users = $i.sharedUsers
                $hash.SharedUser = [AtlassianPS.JiraPS.UserList]@{
                    Size       = $users.size
                    MaxResults = $users.'max-results'
                    StartIndex = $users.'start-index'
                    EndIndex   = $users.'end-index'
                    Items      = [AtlassianPS.JiraPS.User[]]@(ConvertTo-JiraUser -InputObject $users.items)
                }
            }
            if ($null -ne $i.subscriptions) {
                $subscriptions = $i.subscriptions
                $hash.Subscription = [AtlassianPS.JiraPS.FilterSubscriptionList]@{
                    Size       = $subscriptions.size
                    MaxResults = $subscriptions.'max-results'
                    StartIndex = $subscriptions.'start-index'
                    EndIndex   = $subscriptions.'end-index'
                    Items      = [AtlassianPS.JiraPS.FilterSubscription[]]@(ConvertTo-JiraFilterSubscription -InputObject $subscriptions.items)
                }
            }

            if ($PSBoundParameters.ContainsKey('FilterPermissions')) {
                $hash.FilterPermissions = [AtlassianPS.JiraPS.FilterPermission[]]@(ConvertTo-JiraFilterPermission -InputObject $FilterPermissions)
            }
            elseif ($i -is [AtlassianPS.JiraPS.Filter]) { $hash.FilterPermissions = $i.FilterPermissions }
            elseif ($i.sharePermissions) {
                $hash.FilterPermissions = [AtlassianPS.JiraPS.FilterPermission[]]@(ConvertTo-JiraFilterPermission -InputObject $i.sharePermissions)
            }
            else { $hash.FilterPermissions = [AtlassianPS.JiraPS.FilterPermission[]]@() }

            if ($i.description) { $hash.Description = $i.description }

            if ($i.owner) { $hash.Owner = ConvertTo-JiraUser -InputObject $i.owner }

            $result = [AtlassianPS.JiraPS.Filter]$hash

            $result | Add-Member -MemberType AliasProperty -Name 'Favorite' -Value 'Favourite' -Force

            $result
        }
    }
}
