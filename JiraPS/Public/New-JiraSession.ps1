function New-JiraSession {
    <#
    .Synopsis
       Creates a persistent JIRA authenticated session which can be used by other JiraPS functions
    .DESCRIPTION
       This function creates a persistent, authenticated session in to JIRA which can be used by all other
       JiraPS functions instead of explicitly passing parameters.  This removes the need to use the
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
       [JiraPS.Session] An object representing the Jira session
    #>
    [CmdletBinding(SupportsShouldProcess = $false)]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        # Credentials to use to connect to JIRA.
        [Parameter(
            Mandatory = $true
        )]
        [PSCredential] $Credential,

        [Hashtable] $Headers = @{}
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $uri = "$server/rest/api/2/mypermissions"

        # load DefaultParameters for Invoke-WebRequest
        # as the global PSDefaultParameterValues is not used
        $PSDefaultParameterValues = $global:PSDefaultParameterValues

        $SecureCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(
                $('{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password)
            ))
        $Headers.Add('Authorization', "Basic $SecureCreds")
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwrSplat = @{
            Uri             = $uri
            Headers         = $Headers
            Method          = "GET"
            ContentType     = 'application/json; charset=utf-8'
            UseBasicParsing = $true
            SessionVariable = "newSessionVar"
            ErrorAction     = 'SilentlyContinue'
        }

        if ($Headers.ContainsKey("Content-Type")) {
            $iwrSplat["ContentType"] = $Headers["Content-Type"]
            $Headers.Remove("Content-Type")
            $iwrSplat["Headers"] = $Headers
        }

        try {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $webResponse = Invoke-WebRequest @iwrSplat

            Write-Debug "[New-JiraSession] Converting result to JiraSession object"
            $result = ConvertTo-JiraSession -Session $newSessionVar -Username $Credential.UserName

            Write-Debug "[New-JiraSession] Saving session in module's PrivateData"
            if ($MyInvocation.MyCommand.Module.PrivateData) {
                Write-Debug "[New-JiraSession] Adding session result to existing module PrivateData"
                $MyInvocation.MyCommand.Module.PrivateData.Session = $result;
            }
            else {
                Write-Debug "[New-JiraSession] Creating module PrivateData"
                $MyInvocation.MyCommand.Module.PrivateData = @{
                    'Session' = $result;
                }
            }

            Write-Debug "[New-JiraSession] Outputting result"
            Write-Output $result
        }
        catch {
            $err = $_
            $webResponse = $err.Exception.Response
            Write-Debug "[New-JiraSession] Encountered an exception from the Jira server: $err"

            # Test HEADERS if Jira requires a CAPTCHA
            $headerRequiresCaptcha = "X-Seraph-LoginReason"
            $tokenRequiresCaptcha = "AUTHENTICATION_DENIED"
            if (
                $webResponse.Headers[$headerRequiresCaptcha] -and
                ($webResponse.Headers[$headerRequiresCaptcha] -split ",") -contains $tokenRequiresCaptcha
            ) {
                Write-Warning "JIRA requires you to log on to the website before continuing for security reasons."
            }

            Write-Warning "JIRA returned HTTP error $($webResponse.StatusCode.value__) - $($webResponse.StatusCode)"

            # Retrieve body of HTTP response - this contains more useful information about exactly why the error
            # occurred
            $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
            $body = $readStream.ReadToEnd()
            $readStream.Close()
            Write-Debug "Retrieved body of HTTP response for more information about the error (`$body)"

            # Clear the body in case it is not a JSON (but rather html)
            if ($body -match "^[\s\t]*\<html\>") { $body = "" }

            $result = ConvertFrom-Json2 -InputObject $body
            Write-Debug "Converted body from JSON into PSCustomObject (`$result)"
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
