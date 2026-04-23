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
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $result = [AtlassianPS.JiraPS.User]@{
                Key          = $i.key
                AccountId    = $i.accountId
                Name         = $i.name
                DisplayName  = $i.displayName
                EmailAddress = $i.emailAddress
                Active       = if ($null -ne $i.active) { [System.Convert]::ToBoolean($i.active) } else { $false }
                AvatarUrl    = $i.avatarUrls
                TimeZone     = $i.timeZone
                Locale       = $i.locale
                # Initial value taken from the wire payload; overwritten below if
                # the API also returned the expanded `groups` block.
                Groups       = $i.groups.items
                RestUrl      = $i.self
            }

            if ($i.groups) {
                $result.Groups = $i.groups.items.name
            }

            Add-LegacyTypeAlias -InputObject $result -LegacyName 'JiraPS.User'
        }
    }
}
