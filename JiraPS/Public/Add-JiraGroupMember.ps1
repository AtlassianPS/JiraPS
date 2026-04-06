function Add-JiraGroupMember {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [Alias('GroupName')]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $Group,

        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $UserName,
        <#
          #ToDo:CustomClass
          Once we have custom classes, this can also accept ValueFromPipeline
        #>

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $PassThru
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop
        $isCloud = Test-JiraCloudServer -Credential $Credential

        $resourceURi = "$server/rest/api/2/group/user?groupname={0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_group in $Group) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_group [$_group]"

            $groupObj = Get-JiraGroup -GroupName $_group -Credential $Credential -ErrorAction Stop
            $existingMembers = @(Get-JiraGroupMember -Group $_group -Credential $Credential -ErrorAction Stop)
            $users = Resolve-JiraUser -InputObject $UserName -Exact -Credential $Credential

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
                    $parameter = @{
                        URI        = $resourceURi -f $groupObj.Name
                        Method     = "POST"
                        Body       = ConvertTo-Json -InputObject $memberBody
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    if ($PSCmdlet.ShouldProcess($GroupName, "Adding user '$userDisplayIdentifier'.")) {
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
