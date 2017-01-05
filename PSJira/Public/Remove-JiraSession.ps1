function Remove-JiraSession
{
    <#
    .Synopsis
       Removes persistent JIRA authenticated sessions
    .DESCRIPTION
       This function removes persistent JIRA authenticated sessions and closes the sessions for JIRA.
       This can be used to "log out" of JIRA once work is complete.

       If called with the Session parameter, this function will attempt to close the provided
       PSJira.Session object.

       If called with no parameters, this function will close the saved JIRA session in the module's
       PrivateData which is matching the configured JiraConfigServer.
       You can use -All to close alle JIRA sessions
    .EXAMPLE
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Get-JiraIssue TEST-01
       Remove-JiraSession
       This example creates a JIRA session for jiraUsername, runs Get-JiraIssue, and closes this JIRA session.
    .EXAMPLE
       $s = New-JiraSession -Credential (Get-Credential jiraUsername)
       Remove-JiraSession $s
       This example creates a JIRA session and saves it to a variable, then uses the variable reference to
       close the session.
    .EXAMPLE
       Set-JiraConfigServer 'http://jira1.example.com'
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Set-JiraConfigServer 'http://jira2.example.com'
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Set-JiraConfigServer 'http://jira1.example.com'
       Remove-JiraSession
       This Example will create two sessions and delete the first.
    .EXAMPLE
       Set-JiraConfigServer 'http://jira1.example.com'
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Set-JiraConfigServer 'http://jira2.example.com'
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Set-JiraConfigServer 'http://jira1.example.com'
       Remove-JiraSession -All
       This Example will create two sessions and delete both.
    .INPUTS
       [PSJira.Session] A Session object to close.
    .OUTPUTS
       [PSJira.Session] An object representing the Jira session
    #>
    [CmdletBinding()]
    param(
        # A Jira session to be closed. If not specified, this function will use a saved session.
        [Parameter(Mandatory = $false,
                    Position = 0,
                    ValueFromPipeline = $true)]
        [Object[]] $Sessions,

        [Parameter(Mandatory = $false)]
        [Switch] $All
    )

    begin
    {
        try
        {
            Write-Debug "[Remove-JiraSession] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Remove-JiraSession] Encountered an error reading configuration data."
            throw $err
        }

        $uriExt = '/rest/auth/1/session'

        $headers = @{
            'Content-Type' = 'application/json';
        }
    }

    process
    {
        if ($Sessions.Count -eq 0) {
            Write-Debug "[Remove-JiraSession] Session parameter was not supplied. Checking for saved session in module PrivateData"
            if ($All)
            {
                $Sessions = @(Get-JiraSession -All)
            } else {
                $Sessions = @(Get-JiraSession)
            }
        }
        foreach ($Session in $Sessions)
        {
            Write-Debug "[Remove-JiraSession] Validating Session parameter"
            if ($Session.psobject.TypeNames -contains 'PSJira.Session')
            {
                Write-Debug "[Remove-JiraSession] Successfully parsed Session parameter as a PSJira.Session object"
            } else {
                Write-Debug "[Remove-JiraSession] Session parameter is not a PSJira.Session object. Throwing exception"
                throw "Unable to parse parameter [$Session] as a PSJira.Session object"
            }

            Write-Debug "[Remove-JiraSession] Preparing for blastoff!"

            $uri = "$($Session.Server)$uriExt"
            try
            {
                Write-Debug "[Remove-JiraSession] Sending web request to Endpoint $uri"
                $webResponse = Invoke-WebRequest -Uri $uri -Headers $headers -Method Delete -WebSession $Session.WebSession

            } catch {
                $err = $_
                $webResponse = $err.Exception.Response
                Write-Debug "[Remove-JiraSession] Encountered an exception from the Jira server: $err"

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
            Write-Debug "[Remove-JiraSession] Removing session from module's PrivateData"
            if ($MyInvocation.MyCommand.Module.PrivateData)
            {
                Write-Debug "[Remove-JiraSession] Removing session from existing module PrivateData"
                $MyInvocation.MyCommand.Module.PrivateData.Session.Remove($Session.Server);
            } else {
                Write-Debug "[Remove-JiraSession] Creating module PrivateData"
                $MyInvocation.MyCommand.Module.PrivateData = @{
                    'Session' = @{};
                }
            }
        }
    }
}


