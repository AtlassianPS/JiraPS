function New-JiraCandidate {
    <#
    .SYNOPSIS
        Resolve a Jira endpoint and validate deployment and identity before registering a connection.
    #>
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
        $Authentication
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
            $info = Invoke-JiraRequest -Uri '/rest/api/2/serverInfo' -RequestContext $candidate -ErrorAction Stop
        }
        catch {
            if ($_.FullyQualifiedErrorId -notmatch '^InvalidResponse\.Status(403|404|405)(,|$)') { throw }
            Write-Verbose 'Jira server information is unavailable.'
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

        if ($candidate.AuthenticationMode -eq 'Anonymous' -and -not $metadataDeployment) {
            throw 'Anonymous Jira connections require deployment metadata from /rest/api/2/serverInfo. Allow anonymous access to that endpoint or use authenticated Connect-Jira.'
        }

        $username = $null
        $identityDeployment = $null
        $identity = $null
        if ($candidate.AuthenticationMode -ne 'Anonymous') {
            $identity = Invoke-JiraRequest -Uri '/rest/api/2/myself' -RequestContext $candidate -ErrorAction Stop
            $hasAccountId = $identity.accountId -is [String] -and -not [String]::IsNullOrWhiteSpace($identity.accountId)
            $hasName = $identity.name -is [String] -and -not [String]::IsNullOrWhiteSpace($identity.name)
            if (-not $hasAccountId -and -not $hasName) { throw 'Jira did not validate the supplied identity.' }
            if ($hasAccountId -and $hasName) { throw 'Jira returned ambiguous identity information containing both accountId and name.' }

            $identityDeployment = if ($hasAccountId) { 'Cloud' } else { 'Server' }
            $username = if ($hasAccountId) { $identity.accountId } else { $identity.name }
        }

        $resolvedDeployment = $null
        foreach ($deployment in @($metadataDeployment, $gatewayDeployment, $identityDeployment)) {
            if (-not $deployment) { continue }
            if (-not $resolvedDeployment) { $resolvedDeployment = $deployment }

            # Preserve the first source's label while requiring agreement on the Cloud or Server API family.
            if (($deployment -eq 'Cloud') -ne ($resolvedDeployment -eq 'Cloud')) {
                throw 'Conflicting Jira deployment information from serverInfo, the gateway or myself.'
            }
        }

        if ($candidate.CloudId -and -not $candidate.SiteUri) {
            $siteAddress = $info.baseUrl
            if ($null -eq $siteAddress -and $identity.self) {
                [Uri]$identityUri = $null
                if (-not [Uri]::TryCreate([String]$identity.self, [UriKind]::Absolute, [ref]$identityUri) -or
                    $identityUri.UserInfo -or $identityUri.Fragment
                ) {
                    throw 'Jira Cloud myself.self must be a valid Jira resource URL.'
                }
                if ($identityUri.GetLeftPart('Authority') -eq $candidate.BaseUri.GetLeftPart('Authority')) {
                    $null = Resolve-JiraResourceUri -Uri $identityUri -RequestContext $candidate
                }
                else {
                    if (-not $identityUri.AbsolutePath.StartsWith('/rest/', [StringComparison]::Ordinal)) {
                        throw 'Jira Cloud myself.self must be a valid Jira resource URL.'
                    }
                    $siteAddress = $identityUri.GetLeftPart('Authority')
                }
            }

            if ($null -ne $siteAddress) {
                [Uri]$siteUri = $null
                if (-not [Uri]::TryCreate([String]$siteAddress, [UriKind]::Absolute, [ref]$siteUri) -or
                    $siteUri.Scheme -ne 'https' -or $siteUri.Port -ne 443 -or
                    $siteUri.Host -notmatch '^[a-z0-9-]+\.atlassian\.net$' -or
                    $siteUri.AbsolutePath -ne '/' -or $siteUri.UserInfo -or $siteUri.Query -or $siteUri.Fragment
                ) {
                    throw 'Jira Cloud baseUrl or myself.self must identify a valid HTTPS site origin.'
                }

                # Jira returns site URLs in resource links even when validation uses the gateway.
                $endpoint['SiteUri'] = $siteUri
                $gatewayCandidate = $candidate
                $candidate = AtlassianPS.Configuration\New-AtlassianConnectionContext -Product Jira @endpoint @Authentication
                $gatewayCandidate.Dispose()
            }
        }

        $candidate.SetValidationResult($resolvedDeployment, $username)
        $success = $true
        $candidate
    }
    finally {
        if (-not $success) { $candidate.Dispose() }
    }
}
