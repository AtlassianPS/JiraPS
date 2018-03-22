function Invoke-JiraMethod {
    #Requires -Version 3
    [CmdletBinding()]
    param
    (
        # REST API to invoke
        [Parameter( Mandatory )]
        [Uri]
        $URI,

        # Method of the invokation
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE')]
        [String]
        $Method = "GET",

        # Body of the request
        [String]
        $Body,

        # Body of the request should not be encoded
        [Switch]
        $RawBody,

        # Custom headers for the HTTP request
        [Hashtable]
        $Headers = @{},

        # Authentication credentials
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        # Validation of parameters
        if (
            ($Method -in ("POST", "PUT")) -and
            (-not ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Body")))
        ) {
            $message = "The following parameters are required when using the $Method parameter: Body."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # load DefaultParameters for Invoke-WebRequest
        # as the global PSDefaultParameterValues is not used
        $PSDefaultParameterValues = $global:PSDefaultParameterValues

        # pass input to local variable
        # this allows to use the PSBoundParameters for recursion
        $_headers = $Headers

        # Check if a Session is available
        $session = Get-JiraSession -ErrorAction SilentlyContinue

        if ($Credential) {
            $SecureCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(
                    $('{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password)
                ))
            $_headers.Add('Authorization', "Basic $SecureCreds")
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using HTTP Basic authentication with username $($Credential.UserName)"
        }
        elseif ($session) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using WebSession (Username=[$($session.Username)])"
        }
        else {
            $session = $null
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] No Credentials or WebSession provided; using anonymous access"
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwrSplat = @{
            Uri             = $Uri
            Headers         = $_headers
            Method          = $Method
            ContentType     = 'application/json; charset=utf-8'
            UseBasicParsing = $true
            ErrorAction     = 'SilentlyContinue'
            Verbose = $false
        }

        if ($_headers.ContainsKey("Content-Type")) {
            $iwrSplat["ContentType"] = $_headers["Content-Type"]
            $_headers.Remove("Content-Type")
            $iwrSplat["Headers"] = $_headers
        }

        if ($Body) {
            if ($RawBody) {
                $iwrSplat.Add('Body', $Body)
            }
            else {
                # http://stackoverflow.com/questions/15290185/invoke-webrequest-issue-with-special-characters-in-json
                $iwrSplat.Add('Body', [System.Text.Encoding]::UTF8.GetBytes($Body))
            }
        }

        if ($session) {
            $iwrSplat.Add('WebSession', $session.WebSession)
        }

        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] $($iwrSplat.Method) $($iwrSplat.Uri)"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoke-WebRequest with `$iwrSplat: $($iwrSplat | Out-String)"
            $webResponse = Invoke-WebRequest @iwrSplat
        }
        catch {
            # Invoke-WebRequest is hard-coded to throw an exception if the Web request returns a 4xx or 5xx error.
            # This is the best workaround I can find to retrieve the actual results of the request.
            $webResponse = $_.Exception.Response
        }
    }

    end {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Status code:  $($webResponse.StatusCode.value__) - $($webResponse.StatusCode) `n`t`t Executed WebRequest. Access `$webResponse to see details"

        if ($webResponse) {
            if ($webResponse.StatusCode.value__ -gt 399) {
                # Retrieve body of HTTP response - this contains more useful information about exactly why the error occurred
                $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
                $responseBody = $readStream.ReadToEnd()
                $readStream.Close()
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Retrieved body of HTTP response for more information about the error (`$responseBody)"
                $result = ConvertFrom-Json2 -InputObject $responseBody
            }
            else {
                if ($webResponse.Content) {
                    $result = ConvertFrom-Json2 -InputObject $webResponse.Content
                }
            }

            if ($result) {
                if (Get-Member -Name "Errors" -InputObject $result -ErrorAction SilentlyContinue) {
                    Resolve-JiraError $result -WriteError
                }
                else {
                    Write-Output $result
                }
            }
        }
        else {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] No Web result object was returned from JIRA. This is unusual!"
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
