function Remove-JiraGroup {
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
       [JiraPS.Group[]] The JIRA groups to delete
    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]
    param(
        # Group Object or ID to delete.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Alias('GroupName')]
        [Object[]] $Group,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential,

        # Suppress user confirmation.
        [Switch] $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $restUrl = "$server/rest/api/latest/group?groupname={0}"

        if ($Force) {
            Write-Debug "[Remove-JiraGroup] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($g in $Group) {
            Write-Debug "[Remove-JiraGroup] Obtaining reference to group [$g]"
            $groupObj = Get-JiraGroup -InputObject $g -Credential $Credential

            if ($groupObj) {
                $thisUrl = $restUrl -f $groupObj.Name
                Write-Debug "[Remove-JiraGroup] Group URL: [$thisUrl]"

                Write-Debug "[Remove-JiraGroup] Checking for -WhatIf and Confirm"
                if ($PSCmdlet.ShouldProcess($groupObj.Name, "Remove group [$groupObj] from JIRA")) {
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
                }
                else {
                    Write-Debug "[Remove-JiraGroup] Runnning in WhatIf mode or user denied the Confirm prompt; no operation will be performed"
                }
            }
        }
    }

    end {
        if ($Force) {
            Write-Debug "[Remove-JiraGroupMember] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
