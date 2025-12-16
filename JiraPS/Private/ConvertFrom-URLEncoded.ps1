function ConvertFrom-URLEncoded {
    <#
    .SYNOPSIS
        Decode a URL encoded string
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # String to decode
        [Parameter( Mandatory, ValueFromPipeline )]
        [String[]]
        $InputString
    )

    process {
        foreach ($string in $InputString) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Decoding string from URL"
            [System.Web.HttpUtility]::UrlDecode($string)
        }
    }
}
