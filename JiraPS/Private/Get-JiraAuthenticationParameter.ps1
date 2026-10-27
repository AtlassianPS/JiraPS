function Get-JiraAuthenticationParameter {
    [CmdletBinding()]
    [OutputType( [Hashtable] )]
    param(
        [Parameter( Mandatory )]
        [System.Collections.IDictionary]
        $BoundParameters,

        [Switch]
        $UserEmailField
    )

    $result = @{}
    foreach ($key in @('Credential', 'EmailAddress', 'ApiToken', 'PersonalAccessToken', 'Anonymous')) {
        if ($UserEmailField -and $key -eq 'EmailAddress') { continue }
        if (($BoundParameters.Keys -contains $key)) { $result[$key] = $BoundParameters[$key] }
    }

    $result
}
