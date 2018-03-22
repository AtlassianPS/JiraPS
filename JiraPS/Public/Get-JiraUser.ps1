function Get-JiraUser {
    <#
    .SYNOPSIS
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
    [CmdletBinding( DefaultParameterSetName = 'ByUserName' )]
    param(
        # Username, name, or e-mail address of the user. Any of these should
        # return search results from Jira.
        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByUserName' )]
        [ValidateNotNullOrEmpty()]
        [Alias('User', 'Name')]
        [String[]]
        $UserName,

        # User Object of the user.
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByInputObject' )]
        [Object[]] $InputObject,

        # Include inactive users in the search
        [Switch]
        $IncludeInactive,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/user/search?username={0}"

        if ($IncludeInactive) {
            $resourceURi += "&includeInactive=true"
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($InputObject) {
            $UserName = $InputObject.Name
        }

        foreach ($user in $UserName) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$user]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$user [$user]"

            $parameter = @{
                URI        = $resourceURi -f $user
                Method     = "GET"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($result = Invoke-JiraMethod @parameter) {
                $parameter = @{
                    URI        = "{0}&expand=groups" -f $result.self
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraUser -InputObject $result)
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

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
