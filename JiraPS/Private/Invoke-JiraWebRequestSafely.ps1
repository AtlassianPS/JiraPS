function Invoke-JiraWebRequestSafely {
    <#
    .SYNOPSIS
        Capture a web response or request error while suppressing download progress.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [Hashtable]
        $SplatParameters
    )

    $oldProgressPreference = $progressPreference
    $progressPreference = 'silentlyContinue'

    $webResponse = $null
    $exception = $null
    try {
        $webResponse = Invoke-WebRequest @SplatParameters
    }
    catch {
        $exception = $_
        $webResponse = $exception.Exception.Response
    }
    finally {
        $progressPreference = $oldProgressPreference
    }

    [PSCustomObject]@{
        WebResponse = $webResponse
        Exception   = $exception
    }
}
