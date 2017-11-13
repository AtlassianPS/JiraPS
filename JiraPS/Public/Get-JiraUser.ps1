function Get-JiraUser {
    <#
    .Synopsis
       Returns a user from Jira
    .DESCRIPTION
       This function returns information regarding a specified user from Jira.
    .EXAMPLE
       Get-JiraUser -UserName user1 -Credential $cred
       Returns information about the user user1
    .EXAMPLE
       Get-ADUser -filter "Name -like 'John*Smith'" | Select-Object -ExpandProperty samAccountName | Get-JiraUser -Credential $cred
       This example searches Active Directory for the username of John W. Smith, John H. Smith,
       and any other John Smiths, then obtains their JIRA user accounts.
    .INPUTS
       [String[]] Username
       [PSCredential] Credentials to use to connect to Jira
    .OUTPUTS
       [JiraPS.User]
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByUserName')]
    param(
        # Username, name, or e-mail address of the user. Any of these should
        # return search results from Jira.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'ByUserName'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('User', 'Name')]
        [String[]] $UserName,

        # User Object of the user.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'ByInputObject'
        )]
        [Object[]] $InputObject,

        # Include inactive users in the search
        [Switch] $IncludeInactive,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $userSearchUrl = "$server/rest/api/latest/user/search?username={0}"
        if ($IncludeInactive) {
            $userSearchUrl = "$userSearchUrl&includeInactive=true"
        }

        # $userGetUrl = "$server/rest/api/latest/user?username={0}&expand=groups"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            "ByUserName" {
                foreach ($user in $UserName) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing user [$user]"

                    $thisSearchUrl = $userSearchUrl -f $user

                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Searching for $user"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $rawResult = Invoke-JiraMethod -Method Get -URI $thisSearchUrl -Credential $Credential

                    if ($rawResult) {
                        foreach ($r in $rawResult) {
                            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Retreiving user information for $r"

                            $url = '{0}&expand=groups' -f $r.self

                            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                            $thisUserResult = Invoke-JiraMethod -Method Get -URI $url -Credential $Credential

                            if ($thisUserResult) {
                                Write-Output (ConvertTo-JiraUser -InputObject $thisUserResult)
                            }
                            else {
                                $errorMessage = @{
                                    Category         = "InvalidData"
                                    CategoryActivity = "Retrieving user data"
                                    Message          = "No results when searching for user $user"
                                }
                                Write-Error @errorMessage
                            }
                        }
                    }
                    else {
                        $errorMessage = @{
                            Category         = "ObjectNotFound"
                            CategoryActivity = "Searching for user"
                            Message          = "No results when searching for user $user"
                        }
                        Write-Error @errorMessage
                    }
                }

            }
            "ByInputObject" {
                foreach ($i in $InputObject) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing InputObject [$i]"

                    if ('JiraPS.User' -in (Get-Member -InputObject $i).TypeName) {
                        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] User parameter is a JiraPS.User object"
                        $thisUserName = $i.Name
                    }
                    else {
                        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Username is assumed to be [$thisUserName] via ToString()"
                        $thisUserName = $i.ToString()
                    }

                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Invoking myself with the UserName parameter set to search for user [$thisUserName]"
                    Write-Output (Get-JiraUser -UserName $thisUserName -Credential $Credential)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
