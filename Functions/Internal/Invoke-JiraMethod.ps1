function Invoke-JiraMethod
{
    #Requires -Version 3
    [CmdletBinding(DefaultParameterSetName='UseCredential')]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get','Post','Put')]
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
        'Content-Type' = 'application/json';
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

    try
    {
        # Handle all cases of whether $session and $Body are defined. We don't need to worry about $Credential, because 
        # it's part of the headers being sent to Jira
        if ($session -and $Body)
        {
            Write-Debug "[Invoke-JiraMethod] Invoking JIRA method $Method to URI $URI using WebSession and Body"
            $webResponse = Invoke-WebRequest -Uri $URI -Headers $headers -Method $Method -Body $Body -WebSession $session.WebSession -SessionVariable $sessionOut -ErrorAction SilentlyContinue
        } elseif ($session) {
            Write-Debug "[Invoke-JiraMethod] Invoking JIRA method $Method to URI $URI using WebSession"
            $webResponse = Invoke-WebRequest -Uri $URI -Headers $headers -Method $Method -WebSession $session.WebSession -SessionVariable $sessionOut -ErrorAction SilentlyContinue
        } elseif ($Body) {
            Write-Debug "[Invoke-JiraMethod] Invoking JIRA method $Method to URI $URI using Body"
            $webResponse = Invoke-WebRequest -Uri $URI -Headers $headers -Method $Method -Body $Body -ErrorAction SilentlyContinue
        } else {
            Write-Debug "[Invoke-JiraMethod] Invoking JIRA method $Method to URI $URI with no WebSession or Body"
            $webResponse = Invoke-WebRequest -Uri $URI -Headers $headers -Method $Method -ErrorAction SilentlyContinue
        }
    } catch {
        # Invoke-WebRequest is hard-coded to throw an exception if the Web request returns a 4xx or 5xx error.
        # This is the best workaround I can find to retrieve the actual results of the request.
        $webResponse = $_.Exception.Response
    }
    
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
        Write-Debug "[Invoke-JiraMethod] Converted `$body from JSON into PSCustomObject (`$result)"
        Write-Output $result
    } else {
        $result = ConvertFrom-Json -InputObject $webResponse
        if ($result.error)
        {
            Write-Debug "[Invoke-JiraMethod] An error response was received from JIRA; resolving"
            Resolve-JiraError $result -WriteError
        } else {
            Write-Debug "[Invoke-JiraMethod] Outputting results from JIRA"
            Write-Output $result
        }
    }
}