function New-JiraSession {
    # .ExternalHelp ..\JiraPS-help.xml
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Compatibility wrapper establishes local validated state without persisting configuration.'
    )]
    [CmdletBinding()]
    [OutputType( [AtlassianPS.Connection] )]
    param(
        [String]
        $Name,

        [Uri]
        $Uri,

        [PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [String]
        $EmailAddress,

        [Object]
        $ApiToken,

        [Alias('PAT', 'BearerToken')]
        [Object]
        $PersonalAccessToken,

        [Switch]
        $Anonymous,

        [Switch]
        $Default,

        [Hashtable]
        $Headers = @{}
    )

    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    Write-DebugMessage -BoundParameters $PSBoundParameters
    if ($Headers.Count) {
        throw 'New-JiraSession headers are no longer an authentication API. Use explicit authentication parameters.'
    }
    if (-not $Uri) {
        $current = Get-JiraConnection -Default
        $Uri = if ($current) {
            $(if ($current.SiteUri) { $current.SiteUri } else { $current.BaseUri })
        }
        else { Get-JiraConfigServer -ErrorAction Stop }
    }
    if (-not $Uri) { throw 'Specify Uri or configure a migration endpoint before New-JiraSession.' }
    $authentication = Get-JiraAuthenticationParameter -BoundParameters $PSBoundParameters
    $candidate = New-JiraCandidate -Name $Name -Uri $Uri -Authentication $authentication
    try {
        AtlassianPS.Configuration\Register-AtlassianConnection -Connection $candidate -Default:$Default
    }
    finally {
        if ($candidate.State -ne 'Active') { $candidate.Dispose() }
    }
}
