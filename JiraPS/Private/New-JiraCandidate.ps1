function New-JiraCandidate {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Creates an unregistered candidate and performs read-only validation.')]
    [CmdletBinding()]
    param(
        [String]$Name,
        [Parameter(Mandatory)][Uri]$Uri,
        [Parameter(Mandatory)][Hashtable]$Authentication
    )

    $preflight = AtlassianPS.Configuration\New-AtlassianConnectionContext -Product Jira -BaseUri $Uri @Authentication
    $preflight.Dispose()
    $endpoint = Resolve-JiraEndpoint -Uri $Uri -ApiToken:($Authentication.ContainsKey('ApiToken'))
    if ($Name) { $endpoint['Name'] = $Name }
    $candidate = AtlassianPS.Configuration\New-AtlassianConnectionContext -Product Jira @endpoint @Authentication
    $success = $false
    try {
        $info = Invoke-JiraMethod -Uri '/rest/api/2/serverInfo' -RequestContext $candidate -ErrorAction Stop
        if (-not $info.version -or $info.deploymentType -notin @('Cloud', 'Server', 'Data Center')) {
            throw 'The endpoint did not return recognizable Jira server information.'
        }
        if ($candidate.CloudId -and $info.deploymentType -ne 'Cloud') { throw 'Expected Jira Cloud at the resolved gateway.' }
        $username = $null
        if ($candidate.AuthenticationMode -ne 'Anonymous') {
            $identity = Invoke-JiraMethod -Uri '/rest/api/2/myself' -RequestContext $candidate -ErrorAction Stop
            $username = if ($info.deploymentType -eq 'Cloud') { $identity.accountId } else { $identity.name }
            if ([String]::IsNullOrWhiteSpace($username)) { throw 'Jira did not validate the supplied identity.' }
        }
        $candidate.SetValidationResult($info.deploymentType, $username)
        $success = $true
        $candidate
    }
    finally {
        if (-not $success) { $candidate.Dispose() }
    }
}
