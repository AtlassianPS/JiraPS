function Invoke-JiraWebRequestSafely {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [Hashtable]
        $SplatParameters
    )

    # Normal ProgressPreference really slows down invoke-webrequest as it tries to update the screen for bytes received.
    # By setting ProgressPreference to silentlyContinue it doesn't try to update the screen and speeds up the downloads.
    # See https://stackoverflow.com/a/43477248/2641196
    $oldProgressPreference = $progressPreference
    $progressPreference = 'silentlyContinue'

    $webResponse = $null
    $exception = $null
    $sessionVariableName = $null
    $sessionVariableValue = $null

    if ($SplatParameters.ContainsKey('SessionVariable')) {
        $sessionVariableName = [string]$SplatParameters['SessionVariable']
    }

    try {
        $webResponse = Invoke-WebRequest @SplatParameters
    }
    catch {
        $exception = $_
        $webResponse = $exception.Exception.Response
    }
    finally {
        if ($sessionVariableName) {
            $capturedSessionVariable = Get-Variable -Name $sessionVariableName -Scope Local -ErrorAction SilentlyContinue
            if ($capturedSessionVariable) {
                $sessionVariableValue = $capturedSessionVariable.Value
            }
        }

        $progressPreference = $oldProgressPreference
    }

    [PSCustomObject]@{
        WebResponse          = $webResponse
        Exception            = $exception
        SessionVariableName  = $sessionVariableName
        SessionVariableValue = $sessionVariableValue
    }
}
