function Remove-JiraUser {
    <#
    .SYNOPSIS
       Removes an existing user from JIRA
    .DESCRIPTION
       This function removes an existing user from JIRA.

       WARNING: Deleting a JIRA user may cause database integrity problems. See this article for
       details:

       https://confluence.atlassian.com/jira/how-do-i-delete-a-user-account-192519.html
    .EXAMPLE
       Remove-JiraUser -UserName testUser
       Removes the JIRA user TestUser
    .INPUTS
       [JiraPS.User[]] The JIRA users to delete
    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding( ConfirmImpact = 'High', SupportsShouldProcess )]
    param(
        # User Object or ID to delete.
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.User" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraUser',
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

        # Suppress user confirmation.
        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/user?username={0}"

        if ($Force) {
            Write-DebugMessage "[Remove-JiraGroup] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_user in $User) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_user]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_user [$_user]"

            $userObj = Get-JiraUser -InputObject $_user -Credential $Credential -ErrorAction Stop

            $parameter = @{
                URI        = $resourceURi -f $userObj.Name
                Method     = "DELETE"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($userObj.Name, 'Remove user')) {
                Invoke-JiraMethod @parameter
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
