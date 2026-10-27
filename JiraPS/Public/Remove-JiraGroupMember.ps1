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
        $Credential,

        [Switch]
        $PassThru,

        [Switch]
        $Force,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        try {
            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

            $resourceURi = "/rest/api/2/group/user"

            if ($Force) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
                $oldConfirmPreference = $ConfirmPreference
                $ConfirmPreference = 'None'
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            foreach ($_group in $Group) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_group [$_group]"

                foreach ($_user in $User) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_user]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_user [$_user]"

                    $userObj = Resolve-JiraUser -InputObject $_user -Exact -RequestContext $RequestContext -ErrorAction Stop
                    $userIdentifier = if ($isCloud -and $userObj.AccountId) { $userObj.AccountId }
                    else { $userObj.Name }

                    $getParameter = if ($isCloud -and $_group.Id) { @{ groupId = $_group.Id } }
                    else { @{ groupname = $_group.Name } }

                    if ($isCloud) { $getParameter['accountId'] = $userIdentifier }
                    else { $getParameter['username'] = $userIdentifier }
                    $target = if ($_group.Name) { $_group.Name } else { $_group.Id }
                    $parameter = @{
                        URI          = $resourceURi
                        Method       = "DELETE"
                        GetParameter = $getParameter
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    if ($PSCmdlet.ShouldProcess($target, "Remove $($userObj.DisplayName) from group")) { Invoke-JiraMethod -RequestContext $RequestContext @parameter }
                }

                if ($PassThru) { Write-Output $_group }
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            if ($Force) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Restoring ConfirmPreference to [$oldConfirmPreference]"
                $ConfirmPreference = $oldConfirmPreference
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
