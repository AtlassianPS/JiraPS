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
        $Credential,

        [Switch]
        $PassThru,

        [Alias('Session')]
        [AtlassianPS.Connection]$Connection,

        [Alias('Server', 'ServerName')]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete)
                AtlassianPS.Configuration\Get-AtlassianConnection -Product Jira |
                    Where-Object { $_.Name -like "$wordToComplete*" } |
                    ForEach-Object { $_.Name }
            })]
        [String]$ConnectionName,

        [Uri]$Uri,

        [Alias('Email')]
        [String]$EmailAddress,

        [Object]$ApiToken,

        [Alias('PAT', 'BearerToken')]
        [Object]$PersonalAccessToken,

        [Switch]$Anonymous
    )

    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

            $resourceURi = "/rest/api/2/group/user"
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

                $existingMembers = @(Get-JiraGroupMemberOperation -Group $_group -RequestContext $RequestContext -ErrorAction Stop)
                $users = $UserName | Resolve-JiraUser -Exact -RequestContext $RequestContext

                foreach ($user in $users) {

                    $userDisplayIdentifier = if ($user.AccountId) { $user.AccountId } else { $user.Name }
                    $memberExists = if ($isCloud -and $user.AccountId) { @($existingMembers.AccountId) -contains $user.AccountId }
                    elseif ($user.Name) { @($existingMembers.Name) -contains $user.Name }
                    else { $false }
                    if (-not $memberExists) {
                        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] User [$userDisplayIdentifier] is not already in group [$_group]. Adding user."

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
                        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                        if ($PSCmdlet.ShouldProcess($target, "Adding user '$userDisplayIdentifier'.")) {
                            $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter
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
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
