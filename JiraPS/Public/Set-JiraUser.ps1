function Set-JiraUser {
    <#
    .Synopsis
       Modifies user properties in JIRA
    .DESCRIPTION
       This function modifies user properties in JIRA, allowing you to change a user's
       e-mail address, display name, and any other properties supported by JIRA's API.
    .EXAMPLE
       Set-JiraUser -User user1 -EmailAddress user1_new@example.com
       Modifies user1's e-mail address to a new value.  The original value is overridden.
    .EXAMPLE
       Set-JiraUser -User user2 -Properties @{EmailAddress='user2_new@example.com';DisplayName='User 2'}
       This example modifies a user's properties using a hashtable.  This allows updating
       properties that are not exposed as parameters to this function.
    .INPUTS
       [JiraPS.User[]] The JIRA user that should be modified.
    .OUTPUTS
       If the -PassThru parameter is provided, this function will provide a reference
       to the JIRA user modified.  Otherwise, this function does not provide output.
    .NOTES
       It is currently NOT possible to enable and disable users with this function. JIRA
       does not currently provide this ability via their REST API.

       If you'd like to see this ability added to JIRA and to this module, please vote on
       Atlassian's site for this issue: https://jira.atlassian.com/browse/JRA-37294
    #>
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'ByNamedParameters' )]
    param(
        # Username or user object obtained from Get-JiraUser.
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
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

        # Display name to set.
        [Parameter( ParameterSetName = 'ByNamedParameters' )]
        [ValidateNotNullOrEmpty()]
        [String]
        $DisplayName,

        # E-mail address to set.
        [Parameter( ParameterSetName = 'ByNamedParameters' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if ($_ -match '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$') {
                    return $true
                }
                else {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Argument"),
                        'ParameterValue.NotEmail',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $Issue
                    )
                    $errorItem.ErrorDetails = "The value provided does not look like an email address."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    return $false
                }
            }
        )]
        [String]
        $EmailAddress,

        # Hashtable (dictionary) of additional information to set.
        [Parameter( Position = 1, Mandatory, ParameterSetName = 'ByHashtable' )]
        [Hashtable]
        $Property,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential,

        # Whether output should be provided after invoking this function.
        [Switch]
        $PassThru
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/user?username={0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_user in $User) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_user]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_user [$_user]"

            $userObj = Get-JiraUser -UserName $_user -Credential $Credential -ErrorAction Stop

            $requestBody = @{}

            switch ($PSCmdlet.ParameterSetName) {
                'ByNamedParameters' {
                    if (-not ($DisplayName -or $EmailAddress)) {
                        $errorMessage = @{
                            Category         = "InvalidArgument"
                            CategoryActivity = "Validating Arguments"
                            Message          = "The parameters provided do not change the User. No action will be performed"
                        }
                        Write-Error @errorMessage
                        return
                    }

                    if ($DisplayName) {
                        $requestBody.displayName = $DisplayName
                    }

                    if ($EmailAddress) {
                        $requestBody.emailAddress = $EmailAddress
                    }
                }
                'ByHashtable' {
                    $requestBody = $Property
                }
            }

            $parameter = @{
                URI        = $resourceURi -f $userObj.Name
                Method     = "PUT"
                Body       = ConvertTo-Json -InputObject $requestBody -Depth 4
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($UserObj.DisplayName, "Updating user")) {
                $result = Invoke-JiraMethod @parameter

                Write-Output (Get-JiraUser -InputObject $result)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
