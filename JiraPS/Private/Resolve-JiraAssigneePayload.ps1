function Resolve-JiraAssigneePayload {
    <#
    .SYNOPSIS
        Builds the JSON-ready hashtable for setting an issue's assignee.

    .DESCRIPTION
        Encapsulates the decision between the Cloud ('accountId') and
        Server / Data Center ('name') representations of an assignee, and
        between assigning, unassigning, and selecting the project's default.

        Callers are responsible for resolving the target user (if any) and
        for placing the returned hashtable in the correct part of the
        request body; this function only decides the shape of the payload.

    .OUTPUTS
        [hashtable] — one of:
            @{ accountId = <string> }        # Cloud, assign to user
            @{ accountId = $null }           # Cloud, unassign
            @{ name      = <string> }        # Server/DC, assign to user or '-1' for default
            @{ name      = $null }           # Server/DC, unassign (Set-JiraIssue)
            @{ name      = ''   }            # Server/DC, unassign (Invoke-JiraIssueTransition)
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        # The resolved JiraPS.User object, or $null to unassign.
        [Parameter()]
        [PSObject]
        $AssigneeObject,

        # Server/DC string representation for special cases:
        #   - '-1' = project default assignee
        #   - ''   = unassign during transition (Server/DC legacy)
        #   - $null = unassign (Set-JiraIssue on Server/DC)
        # Untyped so that $null and '' remain distinct (PowerShell would
        # otherwise coerce $null -> '' when bound to a [string] parameter).
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        $AssigneeString = $null,

        # $true for Jira Cloud, $false for Jira Server / Data Center.
        [Parameter(Mandatory)]
        [bool]
        $IsCloud
    )

    if ($IsCloud) {
        if ($AssigneeObject) {
            # Reject a non-null user object that has no resolvable AccountId
            # rather than silently fall through to "unassign". This protects
            # against partial / mis-resolved user objects on Cloud where the
            # caller's intent was to assign, not to clear the assignee.
            if (-not $AssigneeObject.AccountId) {
                throw [System.InvalidOperationException]::new(
                    "Cannot build a Cloud assignee payload from a user object with no AccountId. Use -Unassign explicitly to clear the assignee."
                )
            }

            return @{ accountId = $AssigneeObject.AccountId }
        }

        # Cloud unassign: accountId must be $null
        # (Cloud does not accept the 'name' field for assignee operations).
        return @{ accountId = $null }
    }

    # Jira Server / Data Center: the 'name' field is used.
    if ($AssigneeObject) {
        return @{ name = $AssigneeObject.Name }
    }

    return @{ name = $AssigneeString }
}
