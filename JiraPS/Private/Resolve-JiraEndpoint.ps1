function Resolve-JiraEndpoint {
    [CmdletBinding()]
    param([Parameter(Mandatory)][Uri]$Uri, [Switch]$ApiToken)

    if (-not $Uri.IsAbsoluteUri -or $Uri.Scheme -notin @('http', 'https') -or $Uri.UserInfo -or $Uri.Query -or $Uri.Fragment) {
        throw 'Jira endpoint must be an absolute HTTP(S) URI without user information, query or fragment.'
    }
    if (($Uri.Host -eq 'api.atlassian.com' -or $Uri.Host -match '^[a-z0-9-]+\.atlassian\.net$') -and $Uri.Scheme -ne 'https') {
        throw 'Jira Cloud requires HTTPS.'
    }
    $base = $Uri.AbsoluteUri.TrimEnd('/')
    if ($Uri.Host -eq 'api.atlassian.com') {
        $match = [regex]::Match($Uri.AbsolutePath.TrimEnd('/'), '^/ex/jira/(?<id>[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12})$')
        if (-not $match.Success -or $Uri.Port -ne 443 -or [Guid]$match.Groups['id'].Value -eq [Guid]::Empty) { throw 'Expected a Jira gateway endpoint with a valid cloudId.' }
        return @{ BaseUri = [Uri]$base; CloudId = $match.Groups['id'].Value; SiteUri = $null }
    }
    if ($ApiToken -and $Uri.Host -match '^[a-z0-9-]+\.atlassian\.net$' -and $Uri.Port -eq 443) {
        if ($Uri.AbsolutePath -ne '/') { throw 'Supply the normal Jira Cloud site origin.' }
        $discoveryUri = [Uri]($Uri.GetLeftPart('Authority') + '/_edge/tenant_info')
        try {
            $tenant = Invoke-JiraMethod -Uri $discoveryUri -Discovery
            $id = [Guid]::Empty
            if (-not $tenant.cloudId -or -not [Guid]::TryParse([String]$tenant.cloudId, [ref]$id) -or $id -eq [Guid]::Empty) {
                throw 'Invalid cloudId response.'
            }
        }
        catch {
            throw "Jira Cloud discovery failed at /_edge/tenant_info on $($Uri.Host). Check site access and the discovery response."
        }
        return @{
            BaseUri = [Uri]("https://api.atlassian.com/ex/jira/$id")
            SiteUri = [Uri]$Uri.GetLeftPart('Authority')
            CloudId = $id.ToString()
        }
    }
    @{ BaseUri = [Uri]$base; SiteUri = [Uri]$base; CloudId = $null }
}
