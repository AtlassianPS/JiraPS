function Test-Captcha {
    [CmdletBinding()]
    param(
        # Response of Invoke-WebRequest
        [Parameter( Mandatory, ValueFromPipeline )]
        [Microsoft.PowerShell.Commands.WebResponseObject]
        $InputObject
    )

    begin {
        $tokenRequiresCaptcha = "AUTHENTICATION_DENIED"
        $LoginReason = "X-Seraph-LoginReason"
    }

    process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Checking response headers for authentication errors"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Investigating `$InputObject.Headers['$LoginReason']"

        if ($InputObject.Headers -and $InputObject.Headers[$LoginReason]) {
            if ( ($InputObject.Headers[$LoginReason] -split ",") -contains $tokenRequiresCaptcha ) {
                $errorMessage = @{
                    Category         = "AuthenticationError"
                    CategoryActivity = "Authentication"
                    Message          = "JIRA requires you to log on to the website before continuing for security reasons."
                }
                Write-Error @errorMessage
            }
        }
    }

    end {
    }
}
