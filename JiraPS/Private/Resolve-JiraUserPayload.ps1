function Resolve-JiraUserPayload {
    <#
    .SYNOPSIS
        Builds the JSON-ready hashtable for a Jira user reference (assignee, reporter, etc.).

    .DESCRIPTION
        Encapsulates the decision between the Cloud ('accountId') and
        Server / Data Center ('name') representations of a user reference,
        and between assigning to a user, clearing the field, and selecting
        the project's default assignee.

        Callers are responsible for resolving the target user (if any) and
        for placing the returned hashtable in the correct part of the
        request body; this function only decides the shape of the payload.

    .OUTPUTS
        [hashtable] — one of:
            @{ accountId = <string> }        # Cloud, point at user
            @{ accountId = $null }           # Cloud, clear the field
            @{ name      = <string> }        # Server/DC, point at user or '-1' for project default assignee
            @{ name      = $null }           # Server/DC, clear the field

        Empty-string UserString is preserved verbatim ('name = "")
        for callers that need that exact JSON shape (legacy transition unassign).
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [PSObject]
        $UserObject,

        # Server/DC magic values: '-1' = project default assignee, '' =
        # legacy transition unassign, $null = Set-JiraIssue unassign.
        # Untyped so $null and '' remain distinct (PowerShell coerces
        # $null -> '' when bound to a [string] parameter).
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        $UserString = $null,

        [Parameter(Mandatory)]
        [bool]
        $IsCloud
    )

    if ($IsCloud) {
        if ($UserObject) {
            # Reject a non-null user object with no resolvable AccountId
            # rather than silently fall through to "clear the field" — the
            # caller's intent here is to point at a user, not clear it.
            if (-not $UserObject.AccountId) {
                throw [System.InvalidOperationException]::new(
                    "Cannot build a Cloud user payload from a user object with no AccountId. Resolve the user first (e.g. via Get-JiraUser) before passing it to Resolve-JiraUserPayload."
                )
            }

            return @{ accountId = $UserObject.AccountId }
        }

        # Cloud does not accept the 'name' field for user references.
        return @{ accountId = $null }
    }

    if ($UserObject) {
        return @{ name = $UserObject.Name }
    }

    return @{ name = $UserString }
}
