function Remove-JiraGroupMember {
    <#
    .Synopsis
       Removes a user from a JIRA group
    .DESCRIPTION
       This function removes a JIRA user from a JIRA group.
    .EXAMPLE
       Remove-JiraGroupMember -Group testUsers -User jsmith
       This example removes the user jsmith from the group testUsers.
    .EXAMPLE
       Get-JiraGroup 'Project Admins' | Remove-JiraGroupMember -User jsmith
       This example illustrates the use of the pipeline to remove jsmith from
       the "Project Admins" group in JIRA.
    .INPUTS
       [PSJira.Group[]] Group(s) from which users should be removed
    .OUTPUTS
       If the -PassThru parameter is provided, this function will provide a
       reference to the JIRA group modified.  Otherwise, this function does not
       provide output.
    .NOTES
       This REST method is still marked Experimental in JIRA's REST API. That
       means that there is a high probability this will break in future
       versions of JIRA. The function will need to be re-written at that time.
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]
    param(
        # Group Object or ID from which to remove the user(s).
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [Alias('GroupName')]
        [Object[]] $Group,

        # Username or user object obtained from Get-JiraUser
        [Parameter(Mandatory = $true)]
        [Alias('UserName')]
        [Object[]] $User,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential,

        # Whether output should be provided after invoking this function
        [Switch] $PassThru,

        # Suppress user confirmation.
        [Switch] $Force
    )

    begin {
        Write-Debug "[Remove-JiraGroupMember] Reading information from config file"
        try
        {
            Write-Debug "[Remove-JiraGroupMember] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Remove-JiraGroupMember] Encountered an error reading configuration data."
            throw $err
        }

        $restUrl = "$server/rest/api/latest/group/user?groupname={0}&username={1}"

        if ($Force) {
            Write-Debug "[Remove-JiraGroupMember] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        foreach ($g in $Group) {
            Write-Debug "[Remove-JiraGroupMember] Obtaining reference to group [$g]"
            $groupObj = Get-JiraGroup -InputObject $g -Credential $Credential

            if ($groupObj) {
                Write-Debug "[Remove-JiraGroupMember] Obtaining members of group [$g]"
                $groupMembers = Get-JiraGroupMember -Group $g -Credential $Credential | Select-Object -ExpandProperty Name

                foreach ($u in $User) {
                    Write-Debug "[Remove-JiraGroupMember] Obtaining reference to user [$u]"
                    $userObj = Get-JiraUser -InputObject $u -Credential $Credential

                    if ($userObj) {
                        Write-Debug "[Remove-JiraGroupMember] Retrieved user reference [$userObj]"

                        if ($groupMembers -contains $userObj.Name) {
                            $thisRestUrl = $restUrl -f $groupObj.Name, $userObj.Name
                            Write-Debug "[Remove-JiraGroupMember] REST URI: [$thisRestUrl]"

                            Write-Debug "[Remove-JiraGroupMember] Checking for -WhatIf and Confirm"
                            if ($PSCmdlet.ShouldProcess("$groupObj", "Remove $userObj from group")) {
                                Write-Debug "[Remove-JiraGroupMember] Preparing for blastoff!"
                                Invoke-JiraMethod -Method Delete -URI $thisRestUrl -Credential $Credential
                            }
                            else {
                                Write-Debug "[Remove-JiraGroupMember] Runnning in WhatIf mode or user denied the Confirm prompt; no operation will be performed"
                            }
                        }
                        else {
                            Write-Debug "[Remove-JiraGroupMember] User [$u] is not currently a member of group [$g]"
                            Write-Verbose "User [$u] is not currently a member of group [$g]"
                        }
                    }
                    else {
                        Write-Debug "[Remove-JiraGroupMember] Could not identify user [$u]. Writing error message."
                        Write-Error "Unable to identify user [$u]. Check the spelling of this user and ensure that you can access it via Get-JiraUser."
                    }
                }

                if ($PassThru) {
                    Write-Debug "[Remove-JiraGroupMember] -PassThru specified. Obtaining a final reference to group [$g]"
                    $groupObjNew = Get-JiraGroup -InputObject $g -Credential $Credential
                    Write-Debug "[Remove-JiraGroupMember] Outputting group [$groupObjNew]"
                    Write-Output $groupObjNew
                }
            }
            else {
                Write-Debug "[Remove-JiraGroupMember] Could not identify group [$g]"
                Write-Error "Unable to identify group [$g]. Check the spelling of this group and ensure that you can access it via Get-JiraGroup."
            }
        }
    }

    end {
        if ($Force) {
            Write-Debug "[Remove-JiraGroupMember] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Debug "[Remove-JiraGroupMember] Complete"
    }
}




