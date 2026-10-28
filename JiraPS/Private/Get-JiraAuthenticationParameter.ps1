function Get-JiraAuthenticationParameter {
    <#
    .SYNOPSIS
        Copy explicitly supplied authentication parameters for connection creation.

    .DESCRIPTION
        Copies authentication entries without modifying the caller's dictionary.
        Explicit null values, empty credentials and false switches are preserved for validation by AtlassianPS.Configuration.

    .PARAMETER BoundParameters
        The calling command's PSBoundParameters dictionary. It is not modified.

    .OUTPUTS
        System.Collections.Hashtable
        A new hashtable containing only supplied authentication parameters.
        Returns an empty hashtable when none were supplied.

    .EXAMPLE
        $authentication = Get-JiraAuthenticationParameter -BoundParameters $PSBoundParameters
        New-JiraCandidate -Name $Name -Uri $Uri -Authentication $authentication

        Forwards the authentication supplied to Connect-Jira.

    #>
    [CmdletBinding()]
    [OutputType( [Hashtable] )]
    param(
        [Parameter( Mandatory )]
        [System.Collections.IDictionary]
        $BoundParameters
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
        if ($BoundParameters.Keys -contains $parameterName) {
            $authenticationParameters[$parameterName] = $BoundParameters[$parameterName]
        }
    }

    $authenticationParameters
}
