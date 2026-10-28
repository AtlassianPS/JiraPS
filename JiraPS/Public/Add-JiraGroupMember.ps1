function Add-JiraGroupMember {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
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

            $existingMembers = @(Get-JiraGroupMemberOperation -Group $_group -RequestContext $RequestContext -ErrorAction Stop)
            $users = $User | Resolve-JiraUser -RequestContext $RequestContext

            foreach ($user in $users) {
                if (($isCloud -and -not $user.AccountId) -or (-not $isCloud -and -not $user.Name)) {
                    throw 'User requires an accountId on Cloud or a username on Data Center.'
                }

                $userDisplayIdentifier = if ($user.AccountId) { $user.AccountId }
                else { $user.Name }
                $memberExists = if ($isCloud -and $user.AccountId) { @($existingMembers.AccountId) -contains $user.AccountId }
                elseif ($user.Name) { @($existingMembers.Name) -contains $user.Name }
                else { $false }
                if (-not $memberExists) {
                    Write-DebugMessage "User [$userDisplayIdentifier] is not already in group [$_group]. Adding user."

                    $memberBody = if ($isCloud -and $user.AccountId) { @{ 'accountId' = $user.AccountId } }
                    else { @{ 'name' = $user.Name } }
                    $getParameter = if ($isCloud -and $_group.Id) { @{ groupId = $_group.Id } }
                    else { @{ groupname = $_group.Name } }
                    $target = if ($_group.Name) { $_group.Name } else { $_group.Id }
                    $parameter = @{
                        URI          = $resourceURi
                        Method       = "POST"
                        GetParameter = $getParameter
                        Body         = ConvertTo-Json -InputObject $memberBody
                    }
                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    if ($PSCmdlet.ShouldProcess($target, "Adding user '$userDisplayIdentifier'.")) {
                        $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter
                    }
                }
                else {
                    $errorMessage = @{
                        Category = "ResourceExists"
                        ErrorId  = "Adding [$user] to [$_group]"
                        Message  = "User [$user] is already a member of group [$_group]"
                    }
                    WriteError @errorMessage
                }
            }

            if ($PassThru) { Write-Output (ConvertTo-JiraGroup -InputObject $result) }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
