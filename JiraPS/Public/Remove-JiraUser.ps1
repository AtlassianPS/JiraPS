function Remove-JiraUser {
    <#
    .Synopsis
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
    [CmdletBinding(
        ConfirmImpact = 'High',
        SupportsShouldProcess = $true
    )]
    param(
        # User Object or ID to delete.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Alias('UserName')]
        [Object[]] $User,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential,

        # Suppress user confirmation.
        [Switch] $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $userURL = "$server/rest/api/latest/user?username={0}"

        if ($Force) {
            Write-Debug "[Remove-JiraGroup] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($u in $User) {
            Write-Debug "[Remove-JiraUser] Obtaining reference to user [$u]"
            $userObj = Get-JiraUser -InputObject $u -Credential $Credential

            if ($userObj) {
                $thisUrl = $userUrl -f $userObj.Name
                Write-Debug "[Remove-JiraUser] User URL: [$thisUrl]"

                Write-Debug "[Remove-JiraUser] Checking for -WhatIf and Confirm"
                if ($PSCmdlet.ShouldProcess($userObj.Name, 'Completely remove user from JIRA')) {
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
                }
                else {
                    Write-Debug "[Remove-JiraUser] Runnning in WhatIf mode or user denied the Confirm prompt; no operation will be performed"
                }
            }
        }
    }

    end {
        if ($Force) {
            Write-Debug "[Remove-JiraGroupMember] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
