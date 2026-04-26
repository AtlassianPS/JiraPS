function Set-JiraResponseHeaderLogConfiguration {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(DefaultParameterSetName = 'Wildcard')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets in-memory module configuration; nothing to confirm or undo.'
    )]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Wildcard')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Include,

        [Parameter(ParameterSetName = 'Wildcard')]
        [ValidateNotNull()]
        [String[]]
        $Exclude = @(),

        [Parameter(Mandatory, ParameterSetName = 'Regex')]
        [ValidateNotNull()]
        [Regex]
        $Pattern,

        [Parameter(Mandatory, ParameterSetName = 'Disabled')]
        [Switch]
        $Disable
    )

    if ($Disable) {
        $script:JiraResponseHeaderLogConfiguration = $null
        return
    }

    $config = if ($PSCmdlet.ParameterSetName -eq 'Regex') {
        $regexOptions = [System.Text.RegularExpressions.RegexOptions]($Pattern.Options -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        [PSCustomObject]@{
            Mode    = 'Regex'
            Pattern = [Regex]::new($Pattern.ToString(), $regexOptions)
        }
    }
    else {
        $wildcardOptions = [System.Management.Automation.WildcardOptions]::IgnoreCase
        [PSCustomObject]@{
            Mode    = 'Wildcard'
            Include = @($Include | ForEach-Object { [System.Management.Automation.WildcardPattern]::new($_, $wildcardOptions) })
            Exclude = @($Exclude | ForEach-Object { [System.Management.Automation.WildcardPattern]::new($_, $wildcardOptions) })
        }
    }

    # X-Auth-Token is in the warn list (not the unconditional suppress list)
    # because users may legitimately want to inspect their own custom auth-style
    # response headers; the warning gives them a chance to add an explicit Exclude.
    $sensitiveSamples = @($script:AlwaysSuppressedResponseHeaders) + 'X-Auth-Token'
    foreach ($name in $sensitiveSamples) {
        if (Test-JiraResponseHeaderMatch -Configuration $config -Name $name) {
            Write-Warning "[$($MyInvocation.MyCommand.Name)] The configured response-header patterns may match sensitive headers. Cookie and Authorization headers are always suppressed, but review debug logs before sharing them."
            break
        }
    }

    $script:JiraResponseHeaderLogConfiguration = $config
}
