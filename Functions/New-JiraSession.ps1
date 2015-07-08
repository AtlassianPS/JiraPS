function New-JiraSession
{
    [CmdletBinding()]
    param(
        # Credentials to use for the persistent session
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        try
        {
            Write-Debug "[New-JiraSession] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[New-JiraSession] Encountered an error reading configuration data."
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

        Write-Debug "[New-JiraSession] Created JSON syntax in variable `$json."
        Write-Debug "[New-JiraSession] Preparing for blastoff!"

        try
        {
            $webResponse = Invoke-WebRequest -Uri $uri -Headers $headers -Method Post -Body $json -SessionVariable newSessionVar
            Write-Debug "[New-JiraSession] Converting result to JiraSession object"
            $result = ConvertTo-JiraSession -WebResponse $webResponse -Session $newSessionVar -Username $Credential.UserName
            
            Write-Debug "[New-JiraSession] Saving session in module's PrivateData"
            if ($MyInvocation.MyCommand.Module.PrivateData)
            {
                Write-Debug "[New-JiraSession] Adding session result to existing module PrivateData"
                $MyInvocation.MyCommand.Module.PrivateData.Session = $result;
            } else {
                Write-Debug "[New-JiraSession] Creating module PrivateData"
                $MyInvocation.MyCommand.Module.PrivateData = @{
                    'Session' = $result;
                }
            }

            Write-Debug "[New-JiraSession] Outputting result"
            Write-Output $result
        } catch {
            $err = $_
            $webResponse = $err.Exception.Response
            Write-Debug "[New-JiraSession] Encountered an exception from the Jira server: $err"

            Write-Warning "JIRA returned HTTP error $($webResponse.StatusCode.value__) - $($webResponse.StatusCode)"
            
            # Retrieve body of HTTP response - this contains more useful information about exactly why the error 
            # occurred
            $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
            $body = $readStream.ReadToEnd()
            $readStream.Close()
            Write-Debug "Retrieved body of HTTP response for more information about the error (`$body)"
            $result = ConvertFrom-Json -InputObject $body
            Write-Debug "Converted body from JSON into PSCustomObject (`$result)"
        }
    }
}