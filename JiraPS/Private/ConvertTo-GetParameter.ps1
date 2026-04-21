function ConvertTo-GetParameter {
    <#
    .SYNOPSIS
    Generate the GET parameter string for an URL from a hashtable
    #>
    [CmdletBinding()]
    param (
        [Parameter( Position = 0, Mandatory = $true, ValueFromPipeline = $true )]
        [hashtable]$InputObject
    )

    process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Making HTTP get parameter string out of a hashtable"
        Write-Verbose ($InputObject | Out-String)
        if ($InputObject.Count -eq 0) { return '' }
        $pairs = $InputObject.Keys.ForEach({ "$_=$($InputObject[$_])" })
        "?" + ($pairs -join "&")
    }
}
