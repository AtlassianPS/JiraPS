function New-JiraUser {
    <#
    .SYNOPSIS
       Creates a new user in JIRA
    .DESCRIPTION
       This function creates a new user in JIRA.  By default, the new user
       will be notified via e-mail.

       The new user's password is also randomly generated.
    .EXAMPLE
       New-JiraUser -UserName testUser -EmailAddress testUser@example.com
       This example creates a new JIRA user named testUser, and sends a
       notification e-mail.  The user's DisplayName will be set to
       "testUser" since it is not specified.
    .EXAMPLE
       New-JiraUser -UserName testUser2 -EmailAddress testUser2@example.com -DisplayName "Test User 2"
       This example illustrates setting a user's display name during
       user creation.
    .INPUTS
       This function does not accept pipeline input.
    .OUTPUTS
       [JiraPS.User] The user object created
    #>
    [CmdletBinding( SupportsShouldProcess )]
    param(
        # Name of user.
        [Parameter( Mandatory )]
        [String]
        $UserName,

        # E-mail address of the user.
        [Parameter( Mandatory )]
        [Alias('Email')]
        [String]
        $EmailAddress,

        # Display name of the user.
        [String]
        $DisplayName,

        # Should the user receive a notification e-mail?
        [Boolean]
        $Notify = $true,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/user"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $requestBody = @{
            "name"         = $UserName
            "emailAddress" = $EmailAddress
            "notify"       = $Notify
        }

        if ($DisplayName) {
            $requestBody.displayName = $DisplayName
        }
        else {
            Write-DebugMessage "[New-JiraUser] DisplayName was not specified; defaulting to UserName parameter [$UserName]"
            $requestBody.displayName = $UserName
        }

        $parameter = @{
            URI        = $resourceURi
            Method     = "POST"
            Body       = ConvertTo-Json -InputObject $requestBody
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($UserName, "Creating new User on JIRA")) {
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraUser -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
