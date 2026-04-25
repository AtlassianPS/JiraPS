function ConvertTo-JiraRestApiV3Url {
    <#
    .SYNOPSIS
        Rewrites a Jira REST API v2 URL to its v3 equivalent on Jira Cloud.

    .DESCRIPTION
        Most JiraPS cmdlets construct their URIs from the `self` link of
        an issue (which Jira Cloud returns as a v2 URL even on Cloud) or
        from a hard-coded `/rest/api/2/...` path. On Cloud the equivalent
        v3 endpoints are required for several payload shapes (notably ADF
        rich-text fields — see `Resolve-JiraTextFieldPayload`); on Jira
        Server / Data Center the v3 endpoints don't exist and the URL is
        returned unchanged.

        The substitution is anchored at the start of the URL's path
        component (everything before the first `?` or `#`), so a query
        string that happens to contain `/rest/api/2/` is left untouched.
        Only the first occurrence is rewritten.

    .OUTPUTS
        [string] The (possibly rewritten) URL.

    .EXAMPLE
        $uri = ConvertTo-JiraRestApiV3Url -Url $issueObj.RestUrl -IsCloud $isCloud

        Returns "/rest/api/3/issue/12345" on Cloud and the original
        "/rest/api/2/issue/12345" on Server / DC.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $Url,

        [Parameter(Mandatory)]
        [bool]
        $IsCloud
    )

    if (-not $IsCloud) {
        return $Url
    }

    if ([string]::IsNullOrEmpty($Url)) {
        return $Url
    }

    # Match only the first /rest/api/2/ segment that lives in the path
    # component (i.e. before any query string or fragment). The non-greedy
    # `[^?#]*?` ensures we land on the leftmost match — any later
    # occurrences in the same path, or anything inside a `?...` query
    # string / `#fragment`, are preserved verbatim.
    return $Url -replace '^([^?#]*?)/rest/api/2/', '$1/rest/api/3/'
}
