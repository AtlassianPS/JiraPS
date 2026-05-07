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
                RestUrl           = ConvertTo-JiraUriValue $i.self
                ViewUrl           = ConvertTo-JiraUriValue $i.viewUrl
                SearchUrl         = ConvertTo-JiraUriValue $i.searchUrl
                Favourite         = if ($null -ne $i.favourite) { [System.Convert]::ToBoolean($i.favourite) } else { $false }
                FilterPermissions = if ($FilterPermissions) {
                    ConvertTo-JiraTypedArray -Type ([AtlassianPS.JiraPS.FilterPermission]) -InputObject (ConvertTo-JiraFilterPermission ($FilterPermissions))
                }
                elseif ($i.sharePermissions) {
                    ConvertTo-JiraTypedArray -Type ([AtlassianPS.JiraPS.FilterPermission]) -InputObject (ConvertTo-JiraFilterPermission ($i.sharePermissions))
                }
                else {
                    ConvertTo-JiraTypedArray -Type ([AtlassianPS.JiraPS.FilterPermission]) -InputObject $null
                }
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
