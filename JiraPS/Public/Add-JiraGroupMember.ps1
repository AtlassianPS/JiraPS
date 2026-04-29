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
        $UserName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $PassThru
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential

        $resourceURi = "/rest/api/2/group/user"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_group in $Group) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_group [$_group]"

            $existingMembers = @(Get-JiraGroupMember -Group $_group -Credential $Credential -ErrorAction Stop)
            $users = $UserName | Resolve-JiraUser -Exact -Credential $Credential

            foreach ($user in $users) {

                $userDisplayIdentifier = if ($user.AccountId) { $user.AccountId } else { $user.Name }
                $memberExists = $false
                if ($isCloud -and $user.AccountId) {
                    $memberExists = @($existingMembers.AccountId) -contains $user.AccountId
                }
                elseif ($user.Name) {
                    $memberExists = @($existingMembers.Name) -contains $user.Name
                }
                if (-not $memberExists) {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] User [$userDisplayIdentifier] is not already in group [$_group]. Adding user."

                    if ($isCloud -and $user.AccountId) {
                        $memberBody = @{ 'accountId' = $user.AccountId }
                    }
                    else {
                        $memberBody = @{ 'name' = $user.Name }
                    }
                    if ($isCloud -and $_group.Id) {
                        $getParameter = @{ groupId = $_group.Id }
                    }
                    else {
                        $getParameter = @{ groupname = $_group.Name }
                    }
                    $target = if ($_group.Name) { $_group.Name } else { $_group.Id }
                    $parameter = @{
                        URI          = $resourceURi
                        Method       = "POST"
                        GetParameter = $getParameter
                        Body         = ConvertTo-Json -InputObject $memberBody
                        Credential   = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    if ($PSCmdlet.ShouldProcess($target, "Adding user '$userDisplayIdentifier'.")) {
                        $result = Invoke-JiraMethod @parameter
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

            if ($PassThru) {
                Write-Output (ConvertTo-JiraGroup -InputObject $result)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
