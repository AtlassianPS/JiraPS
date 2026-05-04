function Resolve-ErrorWebResponse {
    [CmdletBinding()]
    param (
        $Exception,

        $StatusCode,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Powershell v6+ populates the body of the response into the exception
        if ($Exception.ErrorDetails) {
            $responseBody = $Exception.ErrorDetails.Message
        }
        # Powershell v5.1- has the body of the response in a Stream in the Exception Response
        else {
            $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($Exception.Exception.Response.GetResponseStream())
            $responseBody = $readStream.ReadToEnd()
            $readStream.Close()
        }

        $exception = "Invalid Server Response"
        $errorId = "InvalidResponse.Status$($StatusCode.value__)"
        $errorCategory = "InvalidResult"

        if ($responseBody) {
            # Clear the body in case it is not a JSON (but rather html)
            if ($responseBody -match "^[\s\t]*\<html\>") {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Content is HTML - replacing it with a generic json"
                $responseBody = '{"errorMessages": "Invalid server response. HTML returned."}'
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Retrieved body of HTTP response for more information about the error (`$responseBody)"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Got the following error as `$responseBody"

            try {
                $responseObject = ConvertFrom-Json -InputObject $responseBody -ErrorAction Stop

                $allErrors = [System.Collections.Generic.List[string]]::new()
                if ($null -ne $responseObject.errorMessages) {
                    foreach ($_error in @($responseObject.errorMessages)) {
                        $messageText = "$_error".Trim()
                        if ($messageText) {
                            $null = $allErrors.Add($messageText)
                        }
                    }
                }
                if ($null -ne $responseObject.message) {
                    $messageText = "$($responseObject.message)".Trim()
                    if ($messageText) {
                        $null = $allErrors.Add($messageText)
                    }
                }
                if ($null -ne $responseObject.errors) {
                    if ($responseObject.errors -is [PSCustomObject]) {
                        foreach ($property in $responseObject.errors.PSObject.Properties) {
                            $messageText = "$($property.Value)".Trim()
                            if (-not $messageText) {
                                continue
                            }

                            $fieldName = "$($property.Name)".Trim()
                            if ($fieldName) {
                                $null = $allErrors.Add("${fieldName}: $messageText")
                            }
                            else {
                                $null = $allErrors.Add($messageText)
                            }
                        }
                    }
                    else {
                        foreach ($_error in @($responseObject.errors)) {
                            $messageText = "$_error".Trim()
                            if ($messageText) {
                                $null = $allErrors.Add($messageText)
                            }
                        }
                    }
                }

                if ($allErrors.Count -eq 0) {
                    throw "Unable to handle error"
                }

                foreach ($_error in $allErrors) {
                    $writeErrorSplat = @{
                        Exception    = $exception
                        ErrorId      = $errorId
                        Category     = $errorCategory
                        Message      = $_error
                        TargetObject = $targetObject
                        Cmdlet       = $Cmdlet
                    }
                    WriteError @writeErrorSplat
                }
            }
            catch [ArgumentException] {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] `$responseBody could not be converted from JSON"
                $writeErrorSplat = @{
                    Exception    = $exception
                    ErrorId      = $errorId
                    Category     = $errorCategory
                    Message      = $responseBody
                    TargetObject = $targetObject
                    Cmdlet       = $Cmdlet
                }
                WriteError @writeErrorSplat
            }
            catch {
                $writeErrorSplat = @{
                    Exception    = $exception
                    ErrorId      = $errorId
                    Category     = $errorCategory
                    Message      = "An unknown error occurred."
                    TargetObject = $targetObject
                    Cmdlet       = $Cmdlet
                }
                WriteError @writeErrorSplat
            }
        }
        else {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Response had no Body. Using `$StatusCode for generic error"
            $writeErrorSplat = @{
                Exception = $exception
                ErrorId   = $errorId
                Category  = $errorCategory
                Message   = "Server responded with $StatusCode"
                Cmdlet    = $Cmdlet
            }
            WriteError @writeErrorSplat
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
