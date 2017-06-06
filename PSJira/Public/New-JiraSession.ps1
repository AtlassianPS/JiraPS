function New-JiraSession
{
    <#
    .Synopsis
       Creates a persistent JIRA authenticated session which can be used by other PSJira functions
    .DESCRIPTION
       This function creates a persistent, authenticated session in to JIRA which can be used by all other
       PSJira functions instead of explicitly passing parameters.  This removes the need to use the
       -Credential parameter constantly for each function call.

       This is the equivalent of a browser cookie saving login information.

       Session data is stored in this module's PrivateData; it is not necessary to supply it to each
       subsequent function.
    .EXAMPLE
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Get-JiraIssue TEST-01
       Creates a Jira session for jiraUsername.  The following Get-JiraIssue is run using the
       saved session for jiraUsername.
    .INPUTS
       [PSCredential] The credentials to use to create the Jira session
    .OUTPUTS
       [PSJira.Session] An object representing the Jira session
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
            Write-Debug "[New-JiraSession] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[New-JiraSession] Encountered an error reading configuration data."
            throw $err
        }

        # load DefaultParameters for Invoke-WebRequest
        # as the global PSDefaultParameterValues is not used
        $PSDefaultParameterValues = $global:PSDefaultParameterValues

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
            $webResponse = Invoke-WebRequest -Uri $uri -Headers $headers -Method Post -Body $json -UseBasicParsing -SessionVariable newSessionVar
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

            # Test HEADERS if Jira requires a CAPTCHA
            $tokenRequiresCaptcha  = "AUTHENTICATION_DENIED"
            $headerRequiresCaptcha = "X-Seraph-LoginReason"
            if (($webResponse.Headers[$headerRequiresCaptcha] -split ",") -contains $tokenRequiresCaptcha) {
                Write-Warning "JIRA requires you to log on to the website before continuing for security reasons."
            }

            Write-Warning "JIRA returned HTTP error $($webResponse.StatusCode.value__) - $($webResponse.StatusCode)"

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


