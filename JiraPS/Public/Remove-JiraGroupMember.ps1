function Remove-JiraGroupMember {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'High' )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.GroupTransformation()]
        [Alias('GroupName')]
        [AtlassianPS.JiraPS.Group[]]
        $Group,

        [Parameter( Mandatory )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [Alias('UserName')]
        [AtlassianPS.JiraPS.User[]]
        $User,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $PassThru,

        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential

        $resourceURi = "/rest/api/2/group/user"

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

            foreach ($_user in $User) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_user]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_user [$_user]"

                $userObj = Resolve-JiraUser -InputObject $_user -Exact -Credential $Credential -ErrorAction Stop
                $userIdentifier = if ($isCloud -and $userObj.AccountId) { $userObj.AccountId } else { $userObj.Name }

                if ($isCloud -and $_group.Id) {
                    $getParameter = @{ groupId = $_group.Id }
                }
                else {
                    $getParameter = @{ groupname = $_group.Name }
                }

                if ($isCloud) {
                    $getParameter['accountId'] = $userIdentifier
                }
                else {
                    $getParameter['username'] = $userIdentifier
                }
                $target = if ($_group.Name) { $_group.Name } else { $_group.Id }
                $parameter = @{
                    URI          = $resourceURi
                    Method       = "DELETE"
                    GetParameter = $getParameter
                    Credential   = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($target, "Remove $($userObj.DisplayName) from group")) {
                    Invoke-JiraMethod @parameter
                }
            }

            if ($PassThru) {
                Write-Output $_group
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
