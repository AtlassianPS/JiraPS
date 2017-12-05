function ConvertFrom-URLEncoded {
    <#
    .SYNOPSIS
    Decode a URL encoded string
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # String to decode
        [Parameter( Position = 0, Mandatory, ValueFromPipeline )]
        [String]
        $InputString
    )

    process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Decoding string from URL"
        Write-Output ([System.Web.HttpUtility]::UrlDecode($InputString))
    }
}
