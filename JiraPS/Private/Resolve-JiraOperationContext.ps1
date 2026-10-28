function Resolve-JiraOperationContext {
    <#
    .SYNOPSIS
        Resolve a selected connection or validate an explicit standalone endpoint.
    #>
    [CmdletBinding()]
    [OutputType( [AtlassianPS.Connection] )]
    param(
        [Parameter( Mandatory )]
        [System.Collections.IDictionary]
        $BoundParameters,

        [Switch]
        $UserEmailField
    )

    $parameters = Get-JiraAuthenticationParameter -BoundParameters $BoundParameters -UserEmailField:$UserEmailField
    $selectors = @(
        'Connection',
        'ConnectionName',
        'Uri',
        'BaseUri' |
            Where-Object { ($BoundParameters.Keys -contains $_) }
    )
    if ($selectors.Count -gt 1) { throw 'Supply only one connection selector or standalone endpoint.' }
    foreach ($key in @('Connection', 'ConnectionName')) {
        if (($BoundParameters.Keys -contains $key)) { $parameters[$key] = $BoundParameters[$key] }
    }

    foreach ($key in $selectors) {
        if (-not $BoundParameters[$key]) { throw "Explicit $key cannot be empty." }
    }

    $endpoint = if (($BoundParameters.Keys -contains 'BaseUri')) { $BoundParameters['BaseUri'] }
    elseif (($BoundParameters.Keys -contains 'Uri')) { $BoundParameters['Uri'] }

    if ($endpoint) {
        $candidate = New-JiraCandidate -Name Standalone -Uri $endpoint -Authentication $parameters
        $candidate.MakeStandalone([Guid]::Empty)
        return $candidate
    }

    AtlassianPS.Configuration\Resolve-AtlassianRequestContext -Product Jira @parameters
}
