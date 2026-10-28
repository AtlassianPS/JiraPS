function Get-JiraAuthenticationParameter {
    <#
    .SYNOPSIS
        Selects explicitly supplied authentication parameters for forwarding.

    .DESCRIPTION
        Jira commands receive authentication, connection selectors and operation
        fields together in PSBoundParameters. This helper copies only the
        authentication entries into a new hashtable for splatting into connection
        creation or request-context resolution.

        Parameter presence matters: omitted authentication lets the resolver use
        the selected connection, while explicitly supplied values are validated
        by AtlassianPS.Configuration. Empty credentials, null values and false
        switches are therefore copied unchanged.

    .PARAMETER BoundParameters
        The calling command's PSBoundParameters dictionary. It is not modified.

    .PARAMETER UserEmailField
        Excludes EmailAddress when it describes the Jira user being created or
        updated by New-JiraUser or Set-JiraUser, rather than the identity used
        for authentication. Other authentication parameters are still forwarded.

    .OUTPUTS
        System.Collections.Hashtable
        A new hashtable containing only supplied authentication parameters.
        Returns an empty hashtable when none were supplied.

    .EXAMPLE
        $authentication = Get-JiraAuthenticationParameter -BoundParameters $PSBoundParameters
        New-JiraCandidate -Name $Name -Uri $Uri -Authentication $authentication

        Forwards the authentication supplied to Connect-Jira.

    .EXAMPLE
        $authentication = Get-JiraAuthenticationParameter -BoundParameters $PSBoundParameters -UserEmailField
        AtlassianPS.Configuration\Resolve-AtlassianRequestContext -Product Jira @authentication

        Resolves authentication without treating the Jira user's email address
        as an authentication parameter.
    #>
    [CmdletBinding()]
    [OutputType( [Hashtable] )]
    param(
        [Parameter( Mandatory )]
        [System.Collections.IDictionary]
        $BoundParameters,

        [Switch]
        $UserEmailField
    )

    $authenticationParameterNames = @(
        'Credential',
        'EmailAddress',
        'ApiToken',
        'PersonalAccessToken',
        'Anonymous'
    )

    $authenticationParameters = @{}
    foreach ($parameterName in $authenticationParameterNames) {
        if ($UserEmailField -and $parameterName -eq 'EmailAddress') { continue }

        if ($BoundParameters.Keys -contains $parameterName) {
            $authenticationParameters[$parameterName] = $BoundParameters[$parameterName]
        }
    }

    $authenticationParameters
}
