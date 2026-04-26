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

    $matcher = if ($PSCmdlet.ParameterSetName -eq 'Regex') {
        $regex = [Regex]::new(
            $Pattern.ToString(),
            ($Pattern.Options -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        )
        { param($name) $regex.IsMatch($name) }.GetNewClosure()
    }
    else {
        $wildcardOptions = [System.Management.Automation.WildcardOptions]::IgnoreCase
        $includes = @($Include | ForEach-Object { [System.Management.Automation.WildcardPattern]::new($_, $wildcardOptions) })
        $excludes = @($Exclude | ForEach-Object { [System.Management.Automation.WildcardPattern]::new($_, $wildcardOptions) })
        {
            param($name)
            $included = $false
            foreach ($p in $includes) { if ($p.IsMatch($name)) { $included = $true; break } }
            if (-not $included) { return $false }
            foreach ($p in $excludes) { if ($p.IsMatch($name)) { return $false } }
            $true
        }.GetNewClosure()
    }

    # X-Auth-Token is in the warn list (not the unconditional suppress list)
    # because users may legitimately want to inspect their own custom auth-style
    # response headers; the warning gives them a chance to add an explicit Exclude.
    $sensitiveSamples = @($script:AlwaysSuppressedResponseHeaders) + 'X-Auth-Token'
    foreach ($name in $sensitiveSamples) {
        if (& $matcher $name) {
            Write-Warning "[$($MyInvocation.MyCommand.Name)] The configured response-header patterns may match sensitive headers. Cookie and Authorization headers are always suppressed, but review debug logs before sharing them."
            break
        }
    }

    $script:JiraResponseHeaderLogConfiguration = [PSCustomObject]@{
        Match = $matcher
    }
}
