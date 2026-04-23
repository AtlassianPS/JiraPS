function ConvertTo-JiraUser {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.User])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.User"

            $hash = @{
                Key          = $i.key
                AccountId    = $i.accountId
                Name         = $i.name
                DisplayName  = $i.displayName
                EmailAddress = $i.emailAddress
                Active       = if ($null -ne $i.active) { [System.Convert]::ToBoolean($i.active) } else { $false }
                AvatarUrl    = $i.avatarUrls
                TimeZone     = $i.timeZone
                Locale       = $i.locale
                Groups       = if ($i.groups) { [string[]]@($i.groups.items.name) } else { $null }
                RestUrl      = $i.self
            }

            [AtlassianPS.JiraPS.User]$hash
        }
    }
}
