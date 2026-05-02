function Resolve-JiraGroupPayload {
    <#
    .SYNOPSIS
        Normalizes Jira group responses into the canonical payload expected by ConvertTo-JiraGroup.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [PSObject[]]
        $InputObject,

        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string]
        $RequestedGroupName
    )

    process {
        foreach ($group in $InputObject) {
            $resolvedGroupName = if ($group.name) { $group.name } elseif ($group.groupName) { $group.groupName } else { $RequestedGroupName }

            [PSCustomObject]@{
                groupId = if ($group.groupId) { $group.groupId } elseif ($group.id) { $group.id } else { $null }
                name    = $resolvedGroupName
                self    = if ($group.self) { $group.self } else { $null }
                users   = [PSCustomObject]@{
                    size  = if ($null -ne $group.total) { $group.total } elseif ($group.users) { $group.users.size } else { $null }
                    items = if ($group.users -and $group.users.items) { @($group.users.items) } else { @() }
                }
            }
        }
    }
}
