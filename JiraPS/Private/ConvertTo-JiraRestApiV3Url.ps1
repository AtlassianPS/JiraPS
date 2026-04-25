function ConvertTo-JiraRestApiV3Url {
    <#
    .SYNOPSIS
        Rewrites a Jira REST API v2 URL to its v3 equivalent on Jira Cloud.

    .DESCRIPTION
        Atlassian Document Format (ADF) is only accepted by the Jira Cloud
        platform REST API v3 endpoints. The v2 endpoints continue to require
        plain strings for rich-text fields (description, comment body,
        worklog comment) and reject ADF documents with
        "Operation value must be a string".

        Most JiraPS cmdlets historically construct their URIs from the
        `self` link of an issue (which Jira Cloud returns as a v2 URL even
        on Cloud) or from a hard-coded "/rest/api/2/..." path. To send ADF
        on Cloud, callers need to flip those URLs to "/rest/api/3/..."
        before calling Invoke-JiraMethod.

        On Jira Server / Data Center the v3 endpoints don't exist, so the
        URL is returned unchanged.

        The substitution is anchored at the start of the URL's path
        component (everything before the first `?` or `#`), so a query
        string that happens to contain `/rest/api/2/` (e.g. a callback URL)
        is left untouched. Only the first occurrence is rewritten — agile,
        service-desk, or other plugin URLs that don't begin with
        `/rest/api/2/` are unaffected.

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
