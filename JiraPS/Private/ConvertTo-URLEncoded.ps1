function ConvertTo-URLEncoded {
    <#
    .SYNOPSIS
        Percent-encode a raw query key, query value or path segment.
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
            # .NET Framework limits EscapeDataString input to 32,766 UTF-16 characters.
            $maxChunkLength = 32766
            if ($string.Length -le $maxChunkLength) { [Uri]::EscapeDataString($string); continue }

            $encoded = [System.Text.StringBuilder]::new()
            for ($offset = 0; $offset -lt $string.Length; $offset += $length) {
                $length = [Math]::Min($maxChunkLength, $string.Length - $offset)
                if ($offset + $length -lt $string.Length -and [char]::IsHighSurrogate($string[$offset + $length - 1])) { $length-- }
                $null = $encoded.Append([Uri]::EscapeDataString($string.Substring($offset, $length)))
            }
            $encoded.ToString()
        }
    }
}
