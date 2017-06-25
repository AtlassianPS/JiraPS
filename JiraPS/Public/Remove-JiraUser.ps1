function Remove-JiraUser
{
    <#
    .Synopsis
       Removes an existing user from JIRA
    .DESCRIPTION
       This function removes an existing user from JIRA.

       WARNING: Deleting a JIRA user may cause database integrity problems. See this article for
       details:

       https://confluence.atlassian.com/jira/how-do-i-delete-a-user-account-192519.html
    .EXAMPLE
       Remove-JiraUser -UserName testUser
       Removes the JIRA user TestUser
    .INPUTS
       [JiraPS.User[]] The JIRA users to delete
    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
                   ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [Alias('UserName')]
        [Object[]] $User,

        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential,

        [Switch] $Force
    )

    begin
    {
        Write-Debug "[Remove-JiraUser] Reading information from config file"
        try
        {
            Write-Debug "[Remove-JiraUser] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Remove-JiraUser] Encountered an error reading configuration data."
            throw $err
        }

        $userURL = "$server/rest/api/latest/user?username={0}"

        if ($Force)
        {
            Write-Debug "[Remove-JiraGroup] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process
    {
        foreach ($u in $User)
        {
            Write-Debug "[Remove-JiraUser] Obtaining reference to user [$u]"
            $userObj = Get-JiraUser -InputObject $u -Credential $Credential

            if ($userObj)
            {
                $thisUrl = $userUrl -f $userObj.Name
                Write-Debug "[Remove-JiraUser] User URL: [$thisUrl]"

                Write-Debug "[Remove-JiraUser] Checking for -WhatIf and Confirm"
                if ($PSCmdlet.ShouldProcess($userObj.Name, 'Completely remove user from JIRA'))
                {
                    Write-Debug "[Remove-JiraUser] Preparing for blastoff!"
                    Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
                } else {
                    Write-Debug "[Remove-JiraUser] Runnning in WhatIf mode or user denied the Confirm prompt; no operation will be performed"
                }
            }
        }
    }

    end
    {
        if ($Force)
        {
            Write-Debug "[Remove-JiraGroupMember] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Debug "[Remove-JiraUser] Complete"
    }
}


