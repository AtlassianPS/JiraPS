function New-JiraCandidate {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Creates an unregistered candidate and performs read-only validation.'
    )]
    [CmdletBinding()]
    param(
        [String]
        $Name,

        [Parameter( Mandatory )]
        [Uri]
        $Uri,

        [Parameter( Mandatory )]
        [Hashtable]
        $Authentication,

        [ValidateSet('Cloud', 'Server', 'Data Center')]
        [String]
        $DeploymentType
    )

    $preflight = AtlassianPS.Configuration\New-AtlassianConnectionContext -Product Jira -BaseUri $Uri @Authentication
    $preflight.Dispose()

    $endpoint = Resolve-JiraEndpoint -Uri $Uri -ApiToken:($Authentication.ContainsKey('ApiToken'))
    if ($Name) { $endpoint['Name'] = $Name }

    $candidate = AtlassianPS.Configuration\New-AtlassianConnectionContext -Product Jira @endpoint @Authentication
    $success = $false

    try {
        $info = $null
        try {
            $info = Invoke-JiraMethod -Uri '/rest/api/2/serverInfo' -RequestContext $candidate -ErrorAction Stop
        }
        catch {
            if ($_.FullyQualifiedErrorId -notmatch '^InvalidResponse\.Status(403|404|405)(,|$)') { throw }
            Write-Verbose 'Jira server information is unavailable; validating through another Jira endpoint.'
        }

        if (($null -ne $info.deploymentType -and
                ($info.deploymentType -isnot [String] -or
                (-not [String]::IsNullOrWhiteSpace($info.deploymentType) -and $info.deploymentType -notin @('Cloud', 'Server', 'Data Center')))) -or
            ($info.product -and $info.product -ne 'Jira')
        ) {
            throw 'The endpoint did not return recognizable Jira server information.'
        }

        $metadataDeployment = if (-not [String]::IsNullOrWhiteSpace($info.deploymentType)) { $info.deploymentType }
        $gatewayDeployment = if ($candidate.CloudId) { 'Cloud' }

        if ($candidate.CloudId -and -not $candidate.SiteUri) {
            [Uri]$siteUri = $null
            if (-not [Uri]::TryCreate([String]$info.baseUrl, [UriKind]::Absolute, [ref]$siteUri) -or
                $siteUri.Scheme -ne 'https' -or $siteUri.Port -ne 443 -or
                $siteUri.Host -notmatch '^[a-z0-9-]+\.atlassian\.net$' -or
                $siteUri.AbsolutePath -ne '/' -or $siteUri.UserInfo -or $siteUri.Query -or $siteUri.Fragment
            ) {
                throw 'Jira Cloud server information must include a valid HTTPS site origin in baseUrl.'
            }

            # Jira returns site URLs in resource links even when validation uses the gateway.
            $endpoint['SiteUri'] = $siteUri
            $gatewayCandidate = $candidate
            $candidate = AtlassianPS.Configuration\New-AtlassianConnectionContext -Product Jira @endpoint @Authentication
            $gatewayCandidate.Dispose()
        }

        $username = $null
        $identityDeployment = $null
        if ($candidate.AuthenticationMode -ne 'Anonymous') {
            $identity = Invoke-JiraMethod -Uri '/rest/api/2/myself' -RequestContext $candidate -ErrorAction Stop
            $hasAccountId = $identity.accountId -is [String] -and -not [String]::IsNullOrWhiteSpace($identity.accountId)
            $hasName = $identity.name -is [String] -and -not [String]::IsNullOrWhiteSpace($identity.name)
            if (-not $hasAccountId -and -not $hasName) { throw 'Jira did not validate the supplied identity.' }
            if ($hasAccountId -and $hasName) { throw 'Jira returned ambiguous identity information containing both accountId and name.' }

            $identityDeployment = if ($hasAccountId) { 'Cloud' } else { 'Server' }
            $username = if ($hasAccountId) { $identity.accountId } else { $identity.name }
        }

        $deploymentFamilies = @(
            @($metadataDeployment, $DeploymentType, $gatewayDeployment, $identityDeployment) |
                Where-Object { $_ } |
                ForEach-Object { if ($_ -eq 'Cloud') { 'Cloud' } else { 'Server' } } |
                Select-Object -Unique
        )
        if ($deploymentFamilies.Count -gt 1) { throw 'Conflicting Jira deployment information from serverInfo, the gateway, DeploymentType or myself.' }

        if ($candidate.AuthenticationMode -eq 'Anonymous' -and -not $metadataDeployment) {
            if (-not $DeploymentType) {
                throw 'Jira server information did not identify a deployment. Anonymous access requires DeploymentType and an anonymously visible Jira project, or use authenticated Connect-Jira.'
            }

            try {
                $projects = @(Invoke-JiraMethod -Uri '/rest/api/2/project' -RequestContext $candidate -ErrorAction Stop)
            }
            catch {
                if ($_.FullyQualifiedErrorId -notmatch '^InvalidResponse\.Status(401|403|404|405)(,|$)') { throw }
                throw 'Anonymous Jira validation at /rest/api/2/project failed. Allow anonymous project browsing or use authenticated Connect-Jira.'
            }
            $invalidProjects = @($projects | Where-Object {
                    [Uri]$projectUri = $null
                    $_.id -isnot [String] -or $_.id -notmatch '^\d+$' -or
                    $_.key -isnot [String] -or [String]::IsNullOrWhiteSpace($_.key) -or
                    $_.name -isnot [String] -or [String]::IsNullOrWhiteSpace($_.name) -or
                    $_.self -isnot [String] -or -not [Uri]::TryCreate($_.self, [UriKind]::Absolute, [ref]$projectUri) -or
                    $projectUri.Scheme -notin @('http', 'https') -or $projectUri.UserInfo -or $projectUri.Query -or $projectUri.Fragment -or
                    $projectUri.AbsolutePath -notmatch '/rest/api/(2|3)/project/[^/]+$'
                })
            if (-not $projects.Count -or $invalidProjects.Count) {
                throw 'Anonymous Jira validation requires a recognizable project from /rest/api/2/project. Allow anonymous project browsing or use authenticated Connect-Jira.'
            }
        }

        $resolvedDeployment = if ($metadataDeployment) { $metadataDeployment }
        elseif ($DeploymentType) { $DeploymentType }
        elseif ($gatewayDeployment) { $gatewayDeployment }
        else { $identityDeployment }
        $candidate.SetValidationResult($resolvedDeployment, $username)
        $success = $true
        $candidate
    }
    finally {
        if (-not $success) { $candidate.Dispose() }
    }
}
