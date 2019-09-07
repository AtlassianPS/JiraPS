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

        [Alias("Credential")]
        [psobject]
        $Session,

        [Switch]
        $PassThru
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "rest/api/latest/group/user?groupname={0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_group in $Group) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_group [$_group]"

            $groupObj = Get-JiraGroup -GroupName $_group -Session $Session -ErrorAction Stop
            $groupMembers = (Get-JiraGroupMember -Group $_group -Session $Session -ErrorAction Stop).Name

            # At present, it looks like this REST method doesn't support arrays in the Name property...
            # in other words, a single REST call can only add a single group member to a single group.

            # That's kind of annoying.

            # Anyway, this builds a bunch of individual JSON strings with each username in its own Web
            # request, which we'll loop through again in the Process block.
            $users = Resolve-JiraUser -InputObject $UserName -Exact -Session $Session

            foreach ($user in $users) {

                if ($groupMembers -notcontains $user.Name) {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] User [$($user.Name)] is not already in group [$_group]. Adding user."

                    $parameter = @{
                        URI        = $resourceURi -f $groupObj.Name
                        Method     = "POST"
                        Body       = ConvertTo-Json -InputObject @{ 'name' = $user.Name }
                        Session    = $Session
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    if ($PSCmdlet.ShouldProcess($GroupName, "Adding user '$($user.Name)'.")) {
                        $result = Invoke-JiraMethod @parameter
                    }
                }
                else {
                    $errorMessage = @{
                        Category         = "ResourceExists"
                        CategoryActivity = "Adding [$user] to [$_group]"
                        Message          = "User [$user] is already a member of group [$_group]"
                    }
                    Write-Error @errorMessage
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
