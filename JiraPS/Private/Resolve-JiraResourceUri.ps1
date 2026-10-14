function Resolve-JiraResourceUri {
    [CmdletBinding()]
    [OutputType([Uri])]
    param(
        [Parameter(Mandatory)]
        [Uri]$Uri,

        [Parameter(Mandatory)]
        [AtlassianPS.Connection]$RequestContext
    )

    $raw = $Uri.OriginalString.Split('?', 2)[0]
    if ($Uri.OriginalString.Contains('#') -or $raw.Contains([string][char]92) -or $raw -match '(?i)%2e|%2f|%5c|%25|(?:^|/)\.\.(?:/|$)' -or
        ($Uri.IsAbsoluteUri -and ($Uri.Fragment -or $Uri.UserInfo))
    ) {
        throw 'Jira resource URI contains an unsupported path escape, fragment or user information.'
    }

    $base = $RequestContext.BaseUri
    if (-not $Uri.IsAbsoluteUri) {
        if (-not $raw.StartsWith('/') -or $raw.StartsWith('//') -or $raw.StartsWith('/ex/') -or $raw.Contains('#')) { throw 'Relative Jira resource URI must start with one slash.' }
        return [Uri]($base.AbsoluteUri.TrimEnd('/') + $Uri.OriginalString)
    }

    $site = $RequestContext.SiteUri
    if ($RequestContext.CloudId -and $site -and
        $Uri.GetLeftPart('Authority') -eq $site.GetLeftPart('Authority') -and
        $Uri.AbsolutePath.StartsWith('/rest/', [StringComparison]::Ordinal)
    ) {
        return [Uri]($base.AbsoluteUri.TrimEnd('/') + $Uri.PathAndQuery)
    }

    $prefix = $base.AbsolutePath.TrimEnd('/')
    if ($Uri.GetLeftPart('Authority') -ne $base.GetLeftPart('Authority') -or
        ($prefix -and $Uri.AbsolutePath -ne $prefix -and
        -not $Uri.AbsolutePath.StartsWith($prefix + '/', [StringComparison]::Ordinal))
    ) {
        throw 'Jira resource URI does not belong to the selected connection endpoint.'
    }

    $Uri
}
