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
            @{ name      = $null }           # Server/DC, unassign

        Empty-string AssigneeString is preserved verbatim ('name = "")
        for callers that need that exact JSON shape.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [PSObject]
        $AssigneeObject,

        # Server/DC magic values: '-1' = project default, '' = legacy
        # transition unassign, $null = Set-JiraIssue unassign.
        # Untyped so $null and '' remain distinct (PowerShell coerces
        # $null -> '' when bound to a [string] parameter).
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        $AssigneeString = $null,

        [Parameter(Mandatory)]
        [bool]
        $IsCloud
    )

    if ($IsCloud) {
        if ($AssigneeObject) {
            # Reject a non-null user object with no resolvable AccountId
            # rather than silently fall through to "unassign" — the caller's
            # intent here is to assign, not clear.
            if (-not $AssigneeObject.AccountId) {
                throw [System.InvalidOperationException]::new(
                    "Cannot build a Cloud assignee payload from a user object with no AccountId. Use -Unassign explicitly to clear the assignee."
                )
            }

            return @{ accountId = $AssigneeObject.AccountId }
        }

        # Cloud does not accept the 'name' field for assignee operations.
        return @{ accountId = $null }
    }

    if ($AssigneeObject) {
        return @{ name = $AssigneeObject.Name }
    }

    return @{ name = $AssigneeString }
}
