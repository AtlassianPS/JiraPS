function Add-JiraGroupMember {
    <#
    .Synopsis
       Adds a user to a JIRA group
    .DESCRIPTION
       This function adds a JIRA user to a JIRA group.
    .EXAMPLE
       Add-JiraGroupMember -Group testUsers -User jsmith
       This example adds the user jsmith to the group testUsers
    .EXAMPLE
       Get-JiraGroup 'Project Admins' | Add-JiraGroupMember -User jsmith
       This example illustrates the use of the pipeline to add jsmith to the
       "Project Admins" group in JIRA.
    .INPUTS
       [JiraPS.Group[]] Group(s) to which users should be added
    .OUTPUTS
       If the -PassThru parameter is provided, this function will provide a
       reference to the JIRA group modified.  Otherwise, this function does not
       provide output.
    .NOTES
       This REST method is still marked Experimental in JIRA's REST API. That
       means that there is a high probability this will break in future
       versions of JIRA. The function will need to be re-written at that time.
    #>
    [CmdletBinding()]
    param(
        # Group (or list of groups) to which the user(s) will be added.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Alias('GroupName')]
        [Object[]] $Group,

        # Username or user object obtained from Get-JiraUser.
        [Parameter(
            Mandatory = $true
        )]
        [Object[]] $UserName,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential,

        # Whether output should be provided after invoking this function.
        [Switch] $PassThru
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/group/user?groupname={0}"

        # At present, it looks like this REST method doesn't support arrays in the Name property...
        # in other words, a single REST call can only add a single group member to a single group.

        # That's kind of annoying.

        # Anyway, this builds a bunch of individual JSON strings with each username in its own Web
        # request, which we'll loop through again in the Process block.
        $users = Get-JiraUser -InputObject $UserName -Credential $Credential
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_group in $Group) {

            if ($groupObj = Get-JiraGroup -InputObject $_group -Credential $Credential) {
                $groupMembers = (Get-JiraGroupMember -Group $_group -Credential $Credential).Name

                foreach ($user in $users) {
                    if ($groupMembers -notcontains $user.Name) {
                        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] User [${user.Name}] is not already in group [${_group}]. Adding user."

                        $userJson = ConvertTo-Json -InputObject @{
                            'name' = $user.Name;
                        }

                        $parameter = @{
                            URI        = $resourceURi -f $groupObj.Name
                            Method     = "POST"
                            Body       = $userJson
                            Credential = $Credential
                        }
                        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                        $result = Invoke-JiraMethod @parameter
                    }
                    else {
                        $errorMessage = @{
                            Category         = "ObjectNotFound"
                            CategoryActivity = "Adding [$user] to [${_group}]"
                            Message          = "User [$user] is already a member of group [${_group}]"
                        }
                        Write-Error @errorMessage
                    }
                }

                if ($PassThru) {
                    Write-Output (ConvertTo-JiraGroup -InputObject $result)
                }
            }
            else {
                $errorMessage = @{
                    Category          = "ObjectNotFound"
                    CategoryActivity  = "Searching for group"
                    Message           = "Unable to identify group $g."
                    RecommendedAction = "Check the spelling of this group and ensure that you can access it via Get-JiraGroup."
                }
                Write-Error @errorMessage
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
