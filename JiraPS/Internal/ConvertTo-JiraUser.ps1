function ConvertTo-JiraUser {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $props = @{
                'Key'          = $i.key
                'AccountId'    = $i.accountId
                'Name'         = $i.name
                'DisplayName'  = $i.displayName
                'EmailAddress' = $i.emailAddress
                'Active'       = [System.Convert]::ToBoolean($i.active)
                'AvatarUrl'    = $i.avatarUrls
                'TimeZone'     = $i.timeZone
                'Locale'       = $i.locale
                'Groups'       = $i.groups.items
            }

            if ($i.groups) {
                $props.Groups = $i.groups.items.name
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.User')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            Write-Output $result
        }
    }
}
