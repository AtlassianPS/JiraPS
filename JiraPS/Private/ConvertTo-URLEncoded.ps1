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
        $InputString,

        [Switch]
        $PathSegment
    )

    process {
        foreach ($string in $InputString) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Encoding string to URL"
            if ($PathSegment) {
                [Uri]::EscapeDataString($string)
            }
            else {
                [System.Web.HttpUtility]::UrlEncode($string)
            }
        }
    }
}
