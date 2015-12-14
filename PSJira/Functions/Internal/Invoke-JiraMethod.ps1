function Invoke-JiraMethod
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
        #'Content-Type' = 'application/json; charset=utf-8';
    }

    if ($Credential)
    {
        Write-Debug "[Invoke-JiraMethod] Using HTTP Basic authentication with provided credentials for $($Credential.UserName)"
        [String] $Username = $Credential.UserName
        $token = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("${Username}:$($Credential.GetNetworkCredential().Password)"))
        $headers.Add('Authorization', "Basic $token")
        Write-Verbose "Using HTTP Basic authentication with username $($Credential.UserName)"
    } else {
        Write-Debug "[Invoke-JiraMethod] Credentials were not provided. Checking for a saved session"
        $session = Get-JiraSession
        if ($session)
        {
            Write-Debug "[Invoke-JiraMethod] A session was found; using saved session (Username=[$($session.Username)], JSessionID=[$($session.JSessionID)])"
            Write-Verbose "Using saved Web session with username $($session.Username)"
        } else {
            $session = $null
            Write-Debug "[Invoke-JiraMethod] No saved session was found; using anonymous access"
        }
    }

    # http://stackoverflow.com/questions/15290185/invoke-webrequest-issue-with-special-characters-in-json
    $cleanBody = [System.Text.Encoding]::UTF8.GetBytes($Body)

    try
    {
        # Handle all cases of whether $session and $Body are defined. We don't need to worry about $Credential, because
        # it's part of the headers being sent to Jira
        if ($session -and $Body)
        {
            Write-Debug "[Invoke-JiraMethod] Invoking JIRA method $Method to URI $URI using WebSession and Body"
            $webResponse = Invoke-WebRequest -Uri $URI -Headers $headers -Method $Method -Body $cleanBody -WebSession $session.WebSession -ErrorAction SilentlyContinue -ContentType 'application/json; charset=utf-8'
        } elseif ($session) {
            Write-Debug "[Invoke-JiraMethod] Invoking JIRA method $Method to URI $URI using WebSession"
            $webResponse = Invoke-WebRequest -Uri $URI -Headers $headers -Method $Method -WebSession $session.WebSession -ErrorAction SilentlyContinue -ContentType 'application/json; charset=utf-8'
        } elseif ($Body) {
            Write-Debug "[Invoke-JiraMethod] Invoking JIRA method $Method to URI $URI using Body"
            $webResponse = Invoke-WebRequest -Uri $URI -Headers $headers -Method $Method -Body $cleanBody -ErrorAction SilentlyContinue -ContentType 'application/json; charset=utf-8'
        } else {
            Write-Debug "[Invoke-JiraMethod] Invoking JIRA method $Method to URI $URI with no WebSession or Body"
            $webResponse = Invoke-WebRequest -Uri $URI -Headers $headers -Method $Method -ErrorAction SilentlyContinue -ContentType 'application/json; charset=utf-8'
        }
    } catch {
        # Invoke-WebRequest is hard-coded to throw an exception if the Web request returns a 4xx or 5xx error.
        # This is the best workaround I can find to retrieve the actual results of the request.
        $webResponse = $_.Exception.Response
    }

    if ($webResponse)
    {
        Write-Debug "[Invoke-JiraMethod] Status code: $($webResponse.StatusCode)"

        if ($webResponse.StatusCode.value__ -gt 399)
        {
            Write-Warning "JIRA returned HTTP error $($webResponse.StatusCode.value__) - $($webResponse.StatusCode)"

            # Retrieve body of HTTP response - this contains more useful information about exactly why the error
            # occurred
            $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
            $body = $readStream.ReadToEnd()
            $readStream.Close()
            Write-Debug "[Invoke-JiraMethod] Retrieved body of HTTP response for more information about the error (`$body)"
            $result = ConvertFrom-Json -InputObject $body
        } else {
            $result = ConvertFrom-Json -InputObject $webResponse.Content
        }

        if ($result.errors -ne $null)
        {
            Write-Debug "[Invoke-JiraMethod] An error response was received from JIRA; resolving"
            Resolve-JiraError $result -WriteError
        } else {
            Write-Debug "[Invoke-JiraMethod] Outputting results from JIRA"
            Write-Output $result
        }
    } else {
        Write-Debug "[Invoke-JiraMethod] No results were returned from JIRA. This is unusual!"
    }
}


