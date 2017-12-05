function ConvertTo-URLEncoded {
    <#
    .SYNOPSIS
    Encode a string into URL (eg: %20 instead of " ")
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # String to encode
        [Parameter( Position = 0, Mandatory, ValueFromPipeline )]
        [String]
        $InputString
    )

    process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Encoding string to URL"
        Write-Output ([System.Web.HttpUtility]::UrlEncode($InputString))
    }
}
