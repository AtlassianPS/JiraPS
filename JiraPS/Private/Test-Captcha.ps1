function Test-Captcha {
    [CmdletBinding()]
    param(
        # Response of Invoke-WebRequest
        [Parameter( ValueFromPipeline )]
        [PSObject]$InputObject,

        $Caller = $PSCmdlet
    )

    begin {
        $tokenRequiresCaptcha = "AUTHENTICATION_DENIED"
        $LoginReason = "X-Seraph-LoginReason"
    }

    process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Checking response headers for authentication errors"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Investigating `$InputObject.Headers['$LoginReason']"

        if ($InputObject.Headers -and $InputObject.Headers[$LoginReason]) {
            if ( ($InputObject.Headers[$LoginReason] -split ",") -contains $tokenRequiresCaptcha ) {
                $errorMessage = @{
                    Category         = "AuthenticationError"
                    CategoryActivity = "Authentication"
                    Message          = "JIRA requires you to log on to the website before continuing for security reasons."
                }
                $Caller.WriteError($errorMessage)
            }
        }
    }

    end {
    }
}
