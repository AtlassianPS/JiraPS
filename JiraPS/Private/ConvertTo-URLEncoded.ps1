function ConvertTo-URLEncoded {
    <#
    .SYNOPSIS
        Encode a string into URL (eg: %20 instead of " ")
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # String to encode
        [Parameter( Mandatory, ValueFromPipeline )]
        [String[]]
        $InputString
    )

    process {
        foreach ($string in $InputString) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Encoding string to URL"
            [System.Web.HttpUtility]::UrlEncode($string)
        }
    }
}
