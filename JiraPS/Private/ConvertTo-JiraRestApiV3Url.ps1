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

        The substitution is intentionally narrow: it only replaces
        "/rest/api/2/" so we don't accidentally rewrite agile, service-desk,
        or other plugin URLs that happen to contain the string "/2/".

    .OUTPUTS
        [string] The (possibly rewritten) URL.

    .EXAMPLE
        $uri = ConvertTo-JiraRestApiV3Url -Url $issueObj.RestURL -IsCloud $isCloud

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

    return $Url -replace '/rest/api/2/', '/rest/api/3/'
}
