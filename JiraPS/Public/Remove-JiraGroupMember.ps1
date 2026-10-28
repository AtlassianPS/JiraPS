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
        [Switch]
        $PassThru,

        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

        $resourceURi = "/rest/api/2/group/user"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        foreach ($_group in $Group) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-DebugMessage "Processing `$_group [$_group]"

            foreach ($_user in $User) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_user]"
                Write-DebugMessage "Processing `$_user [$_user]"

                $userObj = Resolve-JiraUser -InputObject $_user -RequestContext $RequestContext -ErrorAction Stop
                if (($isCloud -and -not $userObj.AccountId) -or (-not $isCloud -and -not $userObj.Name)) {
                    throw 'User requires an accountId on Cloud or a username on Data Center.'
                }
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
                Write-DebugMessage "Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($target, "Remove $($userObj.DisplayName) from group")) { Invoke-JiraRequest -RequestContext $RequestContext @parameter }
            }

            if ($PassThru) { Write-Output $_group }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
