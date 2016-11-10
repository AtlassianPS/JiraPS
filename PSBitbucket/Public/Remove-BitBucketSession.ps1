function Remove-BitBucketSession
{
    <#
    .Synopsis
       Removes a persistent BitBucket authenticated session
    .DESCRIPTION
       This function removes a persistent BitBucket authenticated session and closes the session for BitBucket.
       This can be used to "log out" of BitBucket once work is complete.

       If called with the Session parameter, this function will attempt to close the provided
       PSBitBucket.Session object.

       If called with no parameters, this function will close the saved BitBucket session in the module's
       PrivateData.
    .EXAMPLE
       New-BitBucketSession -Credential (Get-Credential BitBucketUsername)
       Get-BitBucketIssue TEST-01
       Remove-BitBucketSession
       This example creates a BitBucket session for BitBucketUsername, runs Get-BitBucketIssue, and closes the BitBucket session.
    .EXAMPLE
       $s = New-BitBucketSession -Credential (Get-Credential BitBucketUsername)
       Remove-BitBucketSession $s
       This example creates a BitBucket session and saves it to a variable, then uses the variable reference to
       close the session.
    .INPUTS
       [PSBitBucket.Session] A Session object to close.
    .OUTPUTS
       [PSBitBucket.Session] An object representing the BitBucket session
    #>
    [CmdletBinding()]
    param(
        # A BitBucket session to be closed. If not specified, this function will use a saved session.
        [Parameter(Mandatory = $false,
                    Position = 0,
                    ValueFromPipeline = $true)]
        [Object] $Session
    )

    begin
    {
        try
        {
            Write-Debug "[Remove-BitBucketSession] Reading BitBucket server from config file"
            $server = Get-BitBucketConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Remove-BitBucketSession] Encountered an error reading configuration data."
            throw $err
        }

        $uri = "$server/rest/auth/1/session"

        $headers = @{
            'Content-Type' = 'application/json';
        }
    }

    process
    {
        if ($Session)
        {
            Write-Debug "[Remove-BitBucketSession] Validating Session parameter"
            if ((Get-Member -InputObject $Session).TypeName -eq 'PSBitBucket.Session')
            {
                Write-Debug "[Remove-BitBucketSession] Successfully parsed Session parameter as a PSBitBucket.Session object"
            } else {
                Write-Debug "[Remove-BitBucketSession] Session parameter is not a PSBitBucket.Session object. Throwing exception"
                throw "Unable to parse parameter [$Session] as a PSBitBucket.Session object"
            }
        } else {
            Write-Debug "[Remove-BitBucketSession] Session parameter was not supplied. Checking for saved session in module PrivateData"
            $Session = Get-BitBucketSession
        }

        if ($Session)
        {
            Write-Debug "[Remove-BitBucketSession] Preparing for blastoff!"

            try
            {
                $webResponse = Invoke-WebRequest -Uri $uri -Headers $headers -Method Delete -WebSession $Session.WebSession

                Write-Debug "[Remove-BitBucketSession] Removing session from module's PrivateData"
                if ($MyInvocation.MyCommand.Module.PrivateData)
                {
                    Write-Debug "[Remove-BitBucketSession] Removing session from existing module PrivateData"
                    $MyInvocation.MyCommand.Module.PrivateData.Session = $null;
                } else {
                    Write-Debug "[Remove-BitBucketSession] Creating module PrivateData"
                    $MyInvocation.MyCommand.Module.PrivateData = @{
                        'Session' = $null;
                    }
                }
            } catch {
                $err = $_
                $webResponse = $err.Exception.Response
                Write-Debug "[Remove-BitBucketSession] Encountered an exception from the BitBucket server: $err"

                Write-Warning "BitBucket returned HTTP error $($webResponse.StatusCode.value__) - $($webResponse.StatusCode)"

                # Retrieve body of HTTP response - this contains more useful information about exactly why the error
                # occurred
                $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
                $body = $readStream.ReadToEnd()
                $readStream.Close()
                Write-Debug "Retrieved body of HTTP response for more information about the error (`$body)"
                $result = ConvertFrom-Json2 -InputObject $body
                Write-Debug "Converted body from JSON into PSCustomObject (`$result)"
            }
        } else {
            Write-Verbose "No BitBucket session is saved."
        }
    }
}


