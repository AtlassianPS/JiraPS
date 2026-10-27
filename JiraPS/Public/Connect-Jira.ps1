function Connect-Jira {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'Uri' )]
    [OutputType( [AtlassianPS.Connection] )]
    param(
        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter( Mandatory, ParameterSetName = 'Uri' )]
        [Uri]
        $Uri,

        [Parameter( Mandatory, ParameterSetName = 'Profile' )]
        [ArgumentCompleter( {
                param($commandName, $parameterName, $wordToComplete)
                AtlassianPS.Configuration\Get-AtlassianServerConfiguration |
                    Where-Object { $_.Type -eq 'Jira' -and $_.Name -like "$wordToComplete*" } |
                    ForEach-Object { $_.Name }
            }
        )]
        [String]
        $Profile,

        [PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Email')]
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
        $Default
    )

    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

    if ($Profile) {
        $saved = @(AtlassianPS.Configuration\Get-AtlassianServerConfiguration -Name $Profile)
        if ($saved.Count -ne 1 -or $saved[0].Type -ne 'Jira') { throw 'A Jira profile with that name was not found.' }
        if ($saved[0].Headers.Count -or $saved[0].Certificate) {
            throw 'Remove legacy profile headers and certificates; supply authentication to Connect-Jira.'
        }
        $Uri = $saved[0].Uri
    }

    $authentication = Get-JiraAuthenticationParameter -BoundParameters $PSBoundParameters
    $candidate = New-JiraCandidate -Name $Name -Uri $Uri -Authentication $authentication

    try {
        AtlassianPS.Configuration\Register-AtlassianConnection -Connection $candidate -Default:$Default
    }
    finally {
        if ($candidate.State -ne 'Active') { $candidate.Dispose() }
    }

    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
}
