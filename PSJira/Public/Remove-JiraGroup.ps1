function Remove-JiraGroup
{
    <#
    .Synopsis
       Removes an existing group from JIRA
    .DESCRIPTION
       This function removes an existing group from JIRA.

       Deleting a group does not delete users from JIRA.
    .EXAMPLE
       Remove-JiraGroup -GroupName testGroup
       Removes the JIRA group testGroup
    .INPUTS
       [PSJira.Group[]] The JIRA groups to delete
    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]
    param(
        # Group Object or ID to delete.
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [Alias('GroupName')]
        [Object[]] $Group,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential,

        # Suppress user confirmation.
        [Switch] $Force
    )

    begin
    {
        Write-Debug "[Remove-JiraGroup] Reading information from config file"
        try
        {
            Write-Debug "[Remove-JiraGroup] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch
        {
            $err = $_
            Write-Debug "[Remove-JiraGroup] Encountered an error reading configuration data."
            throw $err
        }

        $restUrl = "$server/rest/api/latest/group?groupname={0}"

        if ($Force)
        {
            Write-Debug "[Remove-JiraGroup] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process
    {
        foreach ($g in $Group)
        {
            Write-Debug "[Remove-JiraGroup] Obtaining reference to group [$g]"
            $groupObj = Get-JiraGroup -InputObject $g -Credential $Credential

            if ($groupObj)
            {
                $thisUrl = $restUrl -f $groupObj.Name
                Write-Debug "[Remove-JiraGroup] Group URL: [$thisUrl]"

                Write-Debug "[Remove-JiraGroup] Checking for -WhatIf and Confirm"
                if ($PSCmdlet.ShouldProcess($groupObj.Name, "Remove group [$groupObj] from JIRA"))
                {
                    Write-Debug "[Remove-JiraGroup] Preparing for blastoff!"
                    Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
                }
                else
                {
                    Write-Debug "[Remove-JiraGroup] Runnning in WhatIf mode or user denied the Confirm prompt; no operation will be performed"
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

        Write-Debug "[Remove-JiraGroup] Complete"
    }
}
