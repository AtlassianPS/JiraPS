function Test-ServerResponse {
    [CmdletBinding()]
    <#
        .SYNOPSIS
            Evaluate the response of the API call
        .LINK
            https://docs.atlassian.com/software/jira/docs/api/7.6.1/com/atlassian/jira/bc/security/login/LoginReason.html
    #>
    param (
        # Response of Invoke-WebRequest
        [Parameter( ValueFromPipeline )]
        [PSObject]$InputObject,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet,

        [int]$RetryCount = 0,

        [int]$MaxRetries = 3
    )

    begin {
        $loginReasonKey = "X-Seraph-LoginReason"
    }

    process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Checking HTTP Response"

        if ($InputObject.Headers -and $InputObject.Headers[$loginReasonKey]) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Checking response headers for authentication errors"
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Investigating `$InputObject.Headers['$loginReasonKey']"

            $loginReason = $InputObject.Headers[$loginReasonKey] -split ","

            switch ($true) {
                { $loginReason -contains "AUTHENTICATED_FAILED" } {
                    $errorParameter = @{
                        ExceptionType = "System.Net.Http.HttpRequestException"
                        Message       = "The user could not be authenticated."
                        ErrorId       = "AuthenticationFailed"
                        Category      = "AuthenticationError"
                        Cmdlet        = $Cmdlet
                    }
                    ThrowError @errorParameter
                }
                { $loginReason -contains "AUTHENTICATION_DENIED" } {
                    $errorParameter = @{
                        ExceptionType = "System.Net.Http.HttpRequestException"
                        Message       = "For security reasons Jira requires you to log on to the website before continuing."
                        ErrorId       = "AuthenticationDenied"
                        Category      = "AuthenticationError"
                        Cmdlet        = $Cmdlet
                    }
                    ThrowError @errorParameter
                }
                { $loginReason -contains "AUTHORISATION_FAILED" } {
                    $errorParameter = @{
                        ExceptionType = "System.Net.Http.HttpRequestException"
                        Message       = "The user could not be authorised."
                        ErrorId       = "AuthorisationFailed"
                        Category      = "AuthenticationError"
                        Cmdlet        = $Cmdlet
                    }
                    ThrowError @errorParameter
                }
                { $loginReason -contains "OK" } { } # The login was OK
                { $loginReason -contains "OUT" } { } # This indicates that person has in fact logged "out"
            }
        }

        if ($InputObject.StatusCode -and ([int]$InputObject.StatusCode -eq 429)) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Got `"429 - Too Many Requests`". Checking retry"
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] #Retry: $RetryCount / $MaxRetries"

            if ($RetryCount -lt $MaxRetries) {
                $_retryAfter = 0
                if ($InputObject.Headers -and $InputObject.Headers['Retry-After']) {
                    $_retryAfter = [int]$InputObject.Headers['Retry-After']
                }
                if ($_retryAfter -lt 1) {
                    $_retryAfter = [math]::Pow(2, $RetryCount + 1)
                }
                Write-Warning "[$($MyInvocation.MyCommand.Name)] Rate limited (HTTP 429). Retrying in $_retryAfter seconds (attempt $($RetryCount + 1) of $MaxRetries)."
                Start-Sleep -Seconds $_retryAfter
                return $true
            }
        }
    }

    end {
    }
}
