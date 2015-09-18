function Remove-JiraGroupMember
{
    [CmdletBinding(SupportsShouldProcess = $true,
                   ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [Alias('GroupName')]
        [Object[]] $Group,

        # Username or user object obtained from Get-JiraUser
        [Parameter(Mandatory = $true)]
        [Alias('UserName')]
        [Object[]] $User,

        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential,

        # Whether output should be provided after invoking this function
        [Switch] $PassThru,

        [Switch] $Force
    )

    begin
    {
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

        if ($Force)
        {
            Write-Debug "[Remove-JiraGroupMember] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process
    {
        foreach ($g in $Group)
        {
            Write-Debug "[Remove-JiraGroupMember] Obtaining reference to group [$g]"
            $groupObj = Get-JiraGroup -InputObject $g -Credential $Credential

            if ($groupObj)
            {
                Write-Debug "[Remove-JiraGroupMember] Obtaining members of group [$g]"
                $groupMembers = Get-JiraGroupMember -Group $g -Credential $Credential | Select-Object -ExpandProperty Name

                foreach ($u in $User)
                {
                    Write-Debug "[Remove-JiraGroupMember] Obtaining reference to user [$u]"
                    $userObj = Get-JiraUser -InputObject $u -Credential $Credential

                    if ($userObj)
                    {
                        Write-Debug "[Remove-JiraGroupMember] Retrieved user reference [$userObj]"

                        if ($groupMembers -contains $userObj.Name)
                        {
                            $thisRestUrl = $restUrl -f $groupObj.Name, $userObj.Name
                            Write-Debug "[Remove-JiraGroupMember] REST URI: [$thisRestUrl]"

                            Write-Debug "[Remove-JiraGroupMember] Checking for -WhatIf and Confirm"
                            if ($PSCmdlet.ShouldProcess("$groupObj", "Remove $userObj from group"))
                            {
                                Write-Debug "[Remove-JiraGroupMember] Preparing for blastoff!"
                                Invoke-JiraMethod -Method Delete -URI $thisRestUrl -Credential $Credential
                            } else {
                                Write-Debug "[Remove-JiraGroupMember] Runnning in WhatIf mode or user denied the Confirm prompt; no operation will be performed"
                            }
                        } else {
                            Write-Debug "[Remove-JiraGroupMember] User [$u] is not currently a member of group [$g]"
                            Write-Verbose "User [$u] is not currently a member of group [$g]"
                        }
                    } else {
                        Write-Debug "[Remove-JiraGroupMember] Could not identify user [$u]. Writing error message."
                        Write-Error "Unable to identify user [$u]. Check the spelling of this user and ensure that you can access it via Get-JiraUser."
                    }
                }

                if ($PassThru)
                {
                    Write-Debug "[Remove-JiraGroupMember] -PassThru specified. Obtaining a final reference to group [$g]"
                    $groupObjNew = Get-JiraGroup -InputObject $g -Credential $Credential
                    Write-Debug "[Remove-JiraGroupMember] Outputting group [$groupObjNew]"
                    Write-Output $groupObjNew
                }
            } else {
                Write-Debug "[Remove-JiraGroupMember] Could not identify group [$g]"
                Write-Error "Unable to identify group [$g]. Check the spelling of this group and ensure that you can access it via Get-JiraGroup."
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

        Write-Debug "[Remove-JiraGroupMember] Complete"
    }
}


