function ConvertTo-JiraUser {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.User objects.
    #>
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.User])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            if ($i -is [AtlassianPS.JiraPS.User]) { $i; continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.User"

            $hash = @{
                Key          = $i.key
                AccountId    = $i.accountId
                AccountType  = ConvertTo-JiraEnum -Type ([AtlassianPS.JiraPS.AccountType]) -Value $i.accountType
                Name         = $i.name
                DisplayName  = $i.displayName
                EmailAddress = $i.emailAddress
                Active       = if ($null -ne $i.active) { [System.Convert]::ToBoolean($i.active) } else { $false }
                AvatarUrl    = if ($null -ne $i.avatarUrls) { ConvertTo-JiraUriMap -InputObject $i.avatarUrls } else { $null }
                TimeZone     = $i.timeZone
                Locale       = $i.locale
                Groups       = if ($i.groups) { , [string[]]@($i.groups.items | ForEach-Object { $_.name }) }
                else { $null }
                RestUrl      = [uri]$i.self
            }

            if ($null -ne $i.deleted) { $hash.Deleted = [System.Convert]::ToBoolean($i.deleted) }

            if ($i.lastLoginTime) { $hash.LastLoginTime = Get-Date $i.lastLoginTime }

            [AtlassianPS.JiraPS.User]$hash
        }
    }
}
