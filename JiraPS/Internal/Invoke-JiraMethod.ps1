function Invoke-JiraMethod {
    #Requires -Version 3
    [CmdletBinding(DefaultParameterSetName = 'UseCredential')]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get', 'Post', 'Put', 'Delete')]
        [String] $Method,

        [Parameter(Mandatory = $true)]
        [String] $URI,

        [ValidateNotNullOrEmpty()]
        [String] $Body,

        [Switch] $RawBody,

        [Hashtable] $Headers = @{},

        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'UseCredential'
        )]
        [System.Management.Automation.PSCredential] $Credential

        #        [Parameter(ParameterSetName='UseSession',
        #                   Mandatory = $true)]
        #        [Object] $Session
    )

    # load DefaultParameters for Invoke-WebRequest
    # as the global PSDefaultParameterValues is not used
    # TODO: find out why JiraPS doesn't need this
    $PSDefaultParameterValues = $global:PSDefaultParameterValues

    if ($Credential) {
        Write-Debug "[Invoke-JiraMethod] Using HTTP Basic authentication with provided credentials for $($Credential.UserName)"
        [String] $Username = $Credential.UserName
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("${Username}:$($Credential.GetNetworkCredential().Password)"))
        $Headers.Add('Authorization', "Basic $token")
        Write-Verbose "Using HTTP Basic authentication with username $($Credential.UserName)"
    }
    else {
        Write-Debug "[Invoke-JiraMethod] Credentials were not provided. Checking for a saved session"
        $session = Get-JiraSession
        if ($session) {
            Write-Debug "[Invoke-JiraMethod] A session was found; using saved session (Username=[$($session.Username)], JSessionID=[$($session.JSessionID)])"
            Write-Verbose "Using saved Web session with username $($session.Username)"
        }
        else {
            $session = $null
            Write-Debug "[Invoke-JiraMethod] No saved session was found; using anonymous access"
        }
    }

    $iwrSplat = @{
        Uri             = $Uri
        Headers         = $Headers
        Method          = $Method
        UseBasicParsing = $true
        ErrorAction     = 'SilentlyContinue'
    }
    if (!($Headers.ContainsKey("Content-Type"))) {
        $iwrSplat["ContentType"] = 'application/json; charset=utf-8'
    }
    else {
        $iwrSplat["ContentType"] = $Headers["Content-Type"]
        $Headers.Remove("Content-Type")
        $iwrSplat["Headers"] = $Headers
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

    if ($Session) {
        $iwrSplat.Add('WebSession', $session.WebSession)
    }

    # We don't need to worry about $Credential, because it's part of the headers being sent to Jira

    try {
        Write-Debug "[Invoke-JiraMethod] Invoking JIRA method $Method to URI $URI"
        $webResponse = Invoke-WebRequest @iwrSplat
    }
    catch {
        # Invoke-WebRequest is hard-coded to throw an exception if the Web request returns a 4xx or 5xx error.
        # This is the best workaround I can find to retrieve the actual results of the request.
        $webResponse = $_.Exception.Response
    }

    if ($webResponse) {
        Write-Debug "[Invoke-JiraMethod] Status code: $($webResponse.StatusCode)"

        if ($webResponse.StatusCode.value__ -gt 399) {
            Write-Warning "JIRA returned HTTP error $($webResponse.StatusCode.value__) - $($webResponse.StatusCode)"

            # Retrieve body of HTTP response - this contains more useful information about exactly why the error
            # occurred
            $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
            $responseBody = $readStream.ReadToEnd()
            $readStream.Close()
            Write-Debug "[Invoke-JiraMethod] Retrieved body of HTTP response for more information about the error (`$responseBody)"
            $result = ConvertFrom-Json2 -InputObject $responseBody
        }
        else {
            if ($webResponse.Content) {
                Write-Debug "[Invoke-JiraMethod] Converting body of response from JSON"
                $result = ConvertFrom-Json2 -InputObject $webResponse.Content
            }
            else {
                Write-Debug "[Invoke-JiraMethod] No content was returned from JIRA."
            }
        }

        if (Get-Member -Name "Errors" -InputObject $result -ErrorAction SilentlyContinue) {
            Write-Debug "[Invoke-JiraMethod] An error response was received from JIRA; resolving"
            Resolve-JiraError $result -WriteError
        }
        else {
            Write-Debug "[Invoke-JiraMethod] Outputting results from JIRA"
            Write-Output $result
        }
    }
    else {
        Write-Debug "[Invoke-JiraMethod] No Web result object was returned from JIRA. This is unusual!"
    }
}
