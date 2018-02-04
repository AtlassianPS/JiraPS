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
       [JiraPS.Group[]] Group(s) from which users should be removed
    .OUTPUTS
       If the -PassThru parameter is provided, this function will provide a
       reference to the JIRA group modified.  Otherwise, this function does not
       provide output.
    .NOTES
       This REST method is still marked Experimental in JIRA's REST API. That
       means that there is a high probability this will break in future
       versions of JIRA. The function will need to be re-written at that time.
    #>
    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'High' )]
    param(
        # Group Object or ID from which to remove the user(s).
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Group" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraGroup',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Group. Expected [JiraPS.Group] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Alias('GroupName')]
        [Object[]]
        $Group,

        # Username or user object obtained from Get-JiraUser
        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.User" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.UotJirauser',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for User. Expected [JiraPS.User] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Alias('UserName')]
        [Object[]]
        $User,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential,

        # Whether output should be provided after invoking this function
        [Switch]
        $PassThru,

        # Suppress user confirmation.
        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/group/user?groupname={0}&username={1}"

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

            $groupObj = Get-JiraGroup -GroupName $_group -Credential $Credential -ErrorAction Stop
            # $groupMembers = (Get-JiraGroupMember -Group $_group -Credential $Credential -ErrorAction Stop).Name

            foreach ($_user in $User) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_user]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_user [$_user]"

                $userObj = Get-JiraUser -InputObject $_user -Credential $Credential -ErrorAction Stop

                # if ($groupMembers -contains $userObj.Name) {
                # TODO: test what jira says
                $parameter = @{
                    URI        = $resourceURi -f $groupObj.Name, $userObj.Name
                    Method     = "DELETE"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($groupObj.Name, "Remove $($userObj.Name) from group")) {
                    Invoke-JiraMethod @parameter
                }
                # }
            }

            if ($PassThru) {
                Write-Output (Get-JiraGroup -InputObject $g -Credential $Credential)
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
