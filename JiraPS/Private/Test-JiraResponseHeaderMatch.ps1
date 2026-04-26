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

    $included = $false
    foreach ($p in $Configuration.Include) {
        if ($p.IsMatch($Name)) { $included = $true; break }
    }
    if (-not $included) { return $false }

    foreach ($p in $Configuration.Exclude) {
        if ($p.IsMatch($Name)) { return $false }
    }

    $true
}
