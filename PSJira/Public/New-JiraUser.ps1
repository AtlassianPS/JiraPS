function New-JiraUser
{
    <#
    .Synopsis
       Creates a new user in JIRA
    .DESCRIPTION
       This function creates a new user in JIRA.  By default, the new user
       will be notified via e-mail.

       The new user's password is also randomly generated.
    .EXAMPLE
       New-JiraUser -UserName testUser -EmailAddress testUser@example.com
       This example creates a new JIRA user named testUser, and sends a
       notification e-mail.  The user's DisplayName will be set to
       "testUser" since it is not specified.
    .EXAMPLE
       New-JiraUser -UserName testUser2 -EmailAddress testUser2@example.com -DisplayName "Test User 2"
       This example illustrates setting a user's display name during
       user creation.
    .INPUTS
       This function does not accept pipeline input.
    .OUTPUTS
       [PSJira.User] The user object created
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String] $UserName,

        [Parameter(Mandatory = $true)]
        [Alias('Email')]
        [String] $EmailAddress,

        [Parameter(Mandatory = $false)]
        [String] $DisplayName,

        # Should the user receive a notification e-mail?
        [Boolean] $Notify = $true,

        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[New-JiraUser] Reading information from config file"
        try
        {
            Write-Debug "[New-JiraUser] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[New-JiraUser] Encountered an error reading configuration data."
            throw $err
        }

        $userURL = "$server/rest/api/latest/user"
    }

    process
    {
        Write-Debug "[New-JiraUser] Defining properties"
        $props = @{
            "name" = $UserName;
            "emailAddress" = $EmailAddress;
        }

        if ($DisplayName)
        {
            $props.displayName = $DisplayName
        } else {
            Write-Debug "[New-JiraUser] DisplayName was not specified; defaulting to UserName parameter [$UserName]"
            $props.displayName = $UserName
        }

        Write-Debug "[New-JiraUser] Setting Notify property to $Notify"
            $props.notify = $Notify

        Write-Debug "[New-JiraUser] Converting to JSON"
        $json = ConvertTo-Json -InputObject $props

        Write-Debug "[New-JiraUser] Preparing for blastoff!"
        $result = Invoke-JiraMethod -Method Post -URI $userURL -Body $json -Credential $Credential

        if ($result)
        {
            if ($result.errors)
            {
                Write-Debug "[New-JiraUser] Jira return an error result object."

                $keys = (Get-Member -InputObject $result.errors | Where-Object -FilterScript {$_.MemberType -eq 'NoteProperty'}).Name
                foreach ($k in $keys)
                {
                    Write-Error "Jira encountered an error: [$($k)] - $($result.errors.$k)"
                }
            } else {
                # OK
                Write-Debug "[New-JiraUser] Converting output object into a Jira user and outputting"
                ConvertTo-JiraUser -InputObject $result
            }
        } else {
            Write-Debug "[New-JiraUser] Jira returned no results to output."
        }
    }
}


