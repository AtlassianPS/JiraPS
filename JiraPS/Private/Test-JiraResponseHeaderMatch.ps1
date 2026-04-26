function Test-JiraResponseHeaderMatch {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory)]
        [PSObject]
        $Configuration,

        [Parameter(Mandatory)]
        [String]
        $Name
    )

    if ($Configuration.Mode -eq 'Regex') {
        return $Configuration.Pattern.IsMatch($Name)
    }

    $wildcardOptions = [System.Management.Automation.WildcardOptions]::IgnoreCase

    $included = $false
    foreach ($p in $Configuration.Include) {
        if ([System.Management.Automation.WildcardPattern]::new($p, $wildcardOptions).IsMatch($Name)) {
            $included = $true
            break
        }
    }
    if (-not $included) { return $false }

    foreach ($p in $Configuration.Exclude) {
        if ([System.Management.Automation.WildcardPattern]::new($p, $wildcardOptions).IsMatch($Name)) {
            return $false
        }
    }

    $true
}
