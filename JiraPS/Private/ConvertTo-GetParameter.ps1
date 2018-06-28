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
        [string]$parameters = "?"
        foreach ($key in $InputObject.Keys) {
            $value = $InputObject[$key]
            $parameters += "$key=$($value)&"
        }
        $parameters -replace ".$"
    }
}
