function New-JiraWebRequestSplat {
    <#
    .SYNOPSIS
        Build an authenticated web request and encode structured JSON or raw payloads.
    .DESCRIPTION
        Strings use UTF-8 and byte arrays are sent unchanged.
        File transfers retain the module's private multipart upload support.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Private helper used internally by Invoke-JiraRequest; it does not perform an external side-effectful action itself.'
    )]
    param(
        [Parameter( Mandatory )]
        [Uri]
        $Uri,

        [Parameter( Mandatory )]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method,

        [Parameter( Mandatory )]
        [Hashtable]
        $Headers,

        [Parameter( Mandatory )]
        [AtlassianPS.Connection]
        $RequestContext,

        [Object]
        $Body,

        [String]
        $ContentType,

        [ValidateRange(0, [int]::MaxValue)]
        [Int]
        $TimeoutSec = 100,

        [String]
        $InFile,

        [String]
        $OutFile,

        [ValidateNotNullOrEmpty()]
        [String]
        $DefaultContentType = "application/json; charset=utf-8"
    )

    $splatParameters = @{
        Uri                = $Uri
        Method             = $Method
        Headers            = $Headers
        UseBasicParsing    = $true
        MaximumRedirection = 0
        ErrorAction        = "Stop"
        Verbose            = $false
    }

    if ($TimeoutSec -gt 0) { $splatParameters["TimeoutSec"] = $TimeoutSec }

    $splatParameters['Headers'] = $Headers.Clone()
    if ($ContentType -and $Headers.ContainsKey('Content-Type')) { throw 'Supply ContentType or the Content-Type header, not both.' }
    if ($Headers.ContainsKey('Content-Type')) {
        $ContentType = $Headers['Content-Type']
        $splatParameters['Headers'].Remove('Content-Type')
    }
    $hasBody = $PSBoundParameters.ContainsKey('Body')
    if (-not $ContentType -and $hasBody) { $ContentType = $DefaultContentType }
    if ($ContentType) { $splatParameters['ContentType'] = $ContentType }

    if ($hasBody) {
        if ($Body -is [Byte[]]) { $splatParameters['Body'] = $Body }
        else {
            $text = if ($Body -is [String]) { $Body }
            else {
                if ($ContentType -notmatch '^application/(?:json|[\w.+-]+\+json)(?:\s*;|$)') {
                    throw 'Structured Body values require a JSON ContentType. Supply a string or byte array for other formats.'
                }
                ConvertTo-Json -InputObject $Body -Depth 100 -Compress -ErrorAction Stop
            }
            $splatParameters['Body'] = [Text.Encoding]::UTF8.GetBytes($text)
        }
    }

    $splatParameters['WebSession'] = $RequestContext.GetWebSession()
    $authorization = $RequestContext.GetAuthorizationHeader()
    if ($authorization) { $splatParameters['Headers']['Authorization'] = $authorization }

    if ($InFile) { $splatParameters["InFile"] = $InFile }
    if ($OutFile) {
        $splatParameters['OutFile'] = $OutFile
        $splatParameters['PassThru'] = $true
    }

    $splatParameters
}
