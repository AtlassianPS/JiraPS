function New-JiraWebRequestSplat {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Private helper used internally by Invoke-JiraMethod; it does not perform an external side-effectful action itself.'
    )]
    param(
        [Parameter(Mandatory)]
        [Uri]
        $Uri,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method,

        [Parameter(Mandatory)]
        [Hashtable]
        $Headers,

        [Parameter(Mandatory)][AtlassianPS.Connection]$RequestContext,

        [String]
        $Body,

        [Switch]
        $RawBody,

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

    if ($Headers.ContainsKey("Content-Type")) {
        $splatParameters["ContentType"] = $Headers["Content-Type"]
        $splatParameters["Headers"].Remove("Content-Type")
        $Headers.Remove("Content-Type")
    }
    elseif ($Body) { $splatParameters["ContentType"] = $DefaultContentType }

    if ($Body) {
        if ($RawBody) { $splatParameters["Body"] = $Body }
        else {
            # Encode Body to preserve special chars
            # http://stackoverflow.com/questions/15290185/invoke-webrequest-issue-with-special-characters-in-json
            $splatParameters["Body"] = [System.Text.Encoding]::UTF8.GetBytes($Body)
        }
    }

    $splatParameters['WebSession'] = $RequestContext.GetWebSession()
    $authorization = $RequestContext.GetAuthorizationHeader()
    if ($authorization) { $splatParameters['Headers']['Authorization'] = $authorization }

    if ($InFile) { $splatParameters["InFile"] = $InFile }
    if ($OutFile) { $splatParameters["OutFile"] = $OutFile }

    $splatParameters
}
