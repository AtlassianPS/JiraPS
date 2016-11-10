function Invoke-BitBucketMethod
{
    #Requires -Version 3
    [CmdletBinding(DefaultParameterSetName='UseCredential')]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get','Post','Put','Delete')]
        [String] $Method,

        [Parameter(Mandatory = $true)]
        [String] $URI,

        [ValidateNotNullOrEmpty()]
        [String] $Body,

        [Parameter(ParameterSetName='UseCredential',
                   Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential

#        [Parameter(ParameterSetName='UseSession',
#                   Mandatory = $true)]
#        [Object] $Session
    )

    $headers = @{
        'Content-Type' = 'application/json; charset=utf-8';
    }

    if ($Credential)
    {
        Write-Debug "[Invoke-BitBucketMethod] Using HTTP Basic authentication with provided credentials for $($Credential.UserName)"
        [String] $Username = $Credential.UserName
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("${Username}:$($Credential.GetNetworkCredential().Password)"))
        $headers.Add('Authorization', "Basic $token")
        Write-Verbose "Using HTTP Basic authentication with username $($Credential.UserName)"
    } else {
        Write-Debug "[Invoke-BitBucketMethod] Credentials were not provided. Checking for a saved session"
        $session = Get-BitBucketSession
        if ($session)
        {
            Write-Debug "[Invoke-BitBucketMethod] A session was found; using saved session (Username=[$($session.Username)], JSessionID=[$($session.JSessionID)])"
            Write-Verbose "Using saved Web session with username $($session.Username)"
        } else {
            $session = $null
            Write-Debug "[Invoke-BitBucketMethod] No saved session was found; using anonymous access"
        }
    }

    $iwrSplat = @{
        Uri             = $Uri
        Headers         = $headers
        Method          = $Method
        UseBasicParsing = $true
        ErrorAction     = 'SilentlyContinue'
    }

    if ($Body)
    {
        # http://stackoverflow.com/questions/15290185/invoke-webrequest-issue-with-special-characters-in-json
        $cleanBody = [System.Text.Encoding]::UTF8.GetBytes($Body)
        $iwrSplat.Add('Body', $cleanBody)
    }

    if ($Session)
    {
        $iwrSplat.Add('WebSession', $session.WebSession)
    }

    # We don't need to worry about $Credential, because it's part of the headers being sent to BitBucket

    try
    {

        Write-Debug "[Invoke-BitBucketMethod] Invoking BitBucket method $Method to URI $URI"
        $webResponse = Invoke-WebRequest @iwrSplat
    } catch {
        # Invoke-WebRequest is hard-coded to throw an exception if the Web request returns a 4xx or 5xx error.
        # This is the best workaround I can find to retrieve the actual results of the request.
        $webResponse = $_.Exception.Response
    }

    if ($webResponse)
    {
        Write-Debug "[Invoke-BitBucketMethod] Status code: $($webResponse.StatusCode)"

        if ($webResponse.StatusCode.value__ -gt 399)
        {
            Write-Warning "BitBucket returned HTTP error $($webResponse.StatusCode.value__) - $($webResponse.StatusCode)"

            # Retrieve body of HTTP response - this contains more useful information about exactly why the error
            # occurred
            $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
            $responseBody = $readStream.ReadToEnd()
            $readStream.Close()
            Write-Debug "[Invoke-BitBucketMethod] Retrieved body of HTTP response for more information about the error (`$responseBody)"
            $result = ConvertFrom-Json2 -InputObject $responseBody
        } else {
            if ($webResponse.Content)
            {
                Write-Debug "[Invoke-BitBucketMethod] Converting body of response from JSON"
                $result = ConvertFrom-Json2 -InputObject $webResponse.Content
            } else {
                Write-Debug "[Invoke-BitBucketMethod] No content was returned from BitBucket."
            }
        }

        if ($result.errors -ne $null)
        {
            Write-Debug "[Invoke-BitBucketMethod] An error response was received from BitBucket; resolving"
            Resolve-BitBucketError $result -WriteError
        } else {
            Write-Debug "[Invoke-BitBucketMethod] Outputting results from BitBucket"
            Write-Output $result
        }
    } else {
        Write-Debug "[Invoke-BitBucketMethod] No Web result object was returned from BitBucket. This is unusual!"
    }
}


