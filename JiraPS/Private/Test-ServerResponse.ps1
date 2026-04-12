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

        $recoverableStatusCodes = @(429, 503)
        $statusCode = [int]$InputObject.StatusCode

        if ($InputObject.StatusCode -and ($statusCode -in $recoverableStatusCodes)) {
            $statusName = switch ($statusCode) {
                429 { "Too Many Requests" }
                503 { "Service Unavailable" }
                default { "Recoverable Error" }
            }
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Got `"$statusCode - $statusName`". Checking retry"
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] #Retry: $RetryCount / $MaxRetries"

            if ($RetryCount -lt $MaxRetries) {
                $_retryAfter = 0
                if ($InputObject.Headers -and $InputObject.Headers['Retry-After']) {
                    $_retryAfter = [int]$InputObject.Headers['Retry-After']
                }
                if ($_retryAfter -lt 1) {
                    $_retryAfter = [math]::Pow(2, $RetryCount + 1) * 10
                }

                $maxRetryDelay = 60
                $jitter = Get-Random -Minimum 0.5 -Maximum 1.0
                $_retryAfter = [math]::Min($maxRetryDelay, $_retryAfter) * $jitter

                if ($statusCode -eq 429 -and $InputObject.Headers) {
                    $rateLimitInfo = @()
                    if ($InputObject.Headers['X-RateLimit-Limit']) {
                        $rateLimitInfo += "Max tokens: $($InputObject.Headers['X-RateLimit-Limit'])"
                    }
                    if ($InputObject.Headers['X-RateLimit-FillRate'] -and $InputObject.Headers['X-RateLimit-Interval-Seconds']) {
                        $rateLimitInfo += "$($InputObject.Headers['X-RateLimit-FillRate']) tokens per $($InputObject.Headers['X-RateLimit-Interval-Seconds'])s"
                    }
                    if ($rateLimitInfo.Count -gt 0) {
                        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Rate limit details: $($rateLimitInfo -join ', ')"
                    }
                }

                Write-Warning "[$($MyInvocation.MyCommand.Name)] $statusName (HTTP $statusCode). Retrying in $([math]::Round($_retryAfter, 1)) seconds (attempt $($RetryCount + 1) of $MaxRetries)."
                Start-Sleep -Seconds $_retryAfter
                return $true
            }
        }
    }

    end {
    }
}
