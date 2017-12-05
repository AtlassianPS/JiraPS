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
    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'High' )]
    param(
        # Group Object or ID to delete.
        [Parameter( Mandatory, ValueFromPipeline )]
        [Alias('GroupName')]
        [Object[]]
        $Group,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential,

        # Suppress user confirmation.
        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/group?groupname={0}"

        if ($Force) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_group in $Group) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_group [$_group]"

            $groupObj = Get-JiraGroup -InputObject $_group -Credential $Credential -ErrorAction Stop

            $parameter = @{
                URI        = $resourceURi -f $groupObj.Name
                Method     = "DELETE"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($groupObj.Name, "Remove group")) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        if ($Force) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
