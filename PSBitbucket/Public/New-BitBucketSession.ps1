function New-BitBucketSession
{
    <#
    .Synopsis
       Creates a persistent BitBucket authenticated session which can be used by other PSBitBucket functions
    .DESCRIPTION
       This function creates a persistent, authenticated session in to BitBucket which can be used by all other
       PSBitBucket functions instead of explicitly passing parameters.  This removes the need to use the
       -Credential parameter constantly for each function call.

       This is the equivalent of a browser cookie saving login information.

       Session data is stored in this module's PrivateData; it is not necessary to supply it to each
       subsequent function.
    .EXAMPLE
       New-BitBucketSession -Credential (Get-Credential BitBucketUsername)
       Get-BitBucketIssue TEST-01
       Creates a BitBucket session for BitBucketUsername.  The following Get-BitBucketIssue is run using the
       saved session for BitBucketUsername.
    .INPUTS
       [PSCredential] The credentials to use to create the BitBucket session
    .OUTPUTS
       [PSBitBucket.Session] An object representing the BitBucket session
    #>
    [CmdletBinding()]
    param(
        # Credentials to use for the persistent session
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        try
        {
            Write-Debug "[New-BitBucketSession] Reading BitBucket server from config file"
            $server = Get-BitBucketConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[New-BitBucketSession] Encountered an error reading configuration data."
            throw $err
        }

        $uri = "$server/rest/auth/1/session"

        $headers = @{
            'Content-Type' = 'application/json';
        }
    }

    process
    {
        $hashtable = @{
            'username' = $Credential.UserName;
            'password' = $Credential.GetNetworkCredential().Password;
        }
        $json = ConvertTo-Json -InputObject $hashtable

        Write-Debug "[New-BitBucketSession] Created JSON syntax in variable `$json."
        Write-Debug "[New-BitBucketSession] Preparing for blastoff!"

        try
        {
            $webResponse = Invoke-WebRequest -Uri $uri -Headers $headers -Method Post -Body $json -UseBasicParsing -SessionVariable newSessionVar
            Write-Debug "[New-BitBucketSession] Converting result to BitBucketSession object"
            $result = ConvertTo-BitBucketSession -WebResponse $webResponse -Session $newSessionVar -Username $Credential.UserName

            Write-Debug "[New-BitBucketSession] Saving session in module's PrivateData"
            if ($MyInvocation.MyCommand.Module.PrivateData)
            {
                Write-Debug "[New-BitBucketSession] Adding session result to existing module PrivateData"
                $MyInvocation.MyCommand.Module.PrivateData.Session = $result;
            } else {
                Write-Debug "[New-BitBucketSession] Creating module PrivateData"
                $MyInvocation.MyCommand.Module.PrivateData = @{
                    'Session' = $result;
                }
            }

            Write-Debug "[New-BitBucketSession] Outputting result"
            Write-Output $result
        } catch {
            $err = $_
            $webResponse = $err.Exception.Response
            Write-Debug "[New-BitBucketSession] Encountered an exception from the BitBucket server: $err"

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
    }
}


