function Get-JiraUser
{
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
       [PSJira.User]
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByUserName')]
    param(
        # Username, name, or e-mail address of the user. Any of these should
        # return search results from Jira.
        [Parameter(ParameterSetName = 'ByUserName',
                   Mandatory = $true,
                   Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [String[]] $UserName,

        [Parameter(ParameterSetName = 'ByInputObject',
                   Mandatory = $true,
                   Position = 0)]
        [Object[]] $InputObject,

        # Include inactive users in the search
        [Switch] $IncludeInactive,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraUser] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Get-JiraIssue] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        Write-Debug "[Get-JiraUser] Building URI for REST call"
        $userUrl = "$server/rest/api/latest/user/search?username={0}"
        if ($IncludeInactive)
        {
            $userUrl = "$userUrl&includeInactive=true"
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByUserName')
        {
            foreach ($u in $UserName)
            {
                Write-Debug "[Get-JiraUser] Processing user [$u]"
                $thisUrl = $userURL -f $u

                Write-Debug "[Get-JiraUser] Preparing for blastoff!"
                $result = Invoke-JiraMethod -Method Get -URI $thisUrl -Credential $Credential

                if ($result)
                {
                    Write-Debug "[Get-JiraUser] Converting result to PSJira.User object"
                    $obj = ConvertTo-JiraUser -InputObject $result

                    Write-Output $obj
                } else {
                    Write-Debug "[Get-JiraUser] JIRA returned no results."
                    Write-Verbose "JIRA returned no results for user [$u]"
                }
            }
        } else {
            foreach ($i in $InputObject)
            {
                Write-Debug "[Get-JiraUser] Processing InputObject [$i]"
                if ((Get-Member -InputObject $i).TypeName -eq 'PSJira.User')
                {
                    Write-Debug "[Get-JiraUser] User parameter is a PSJira.User object"
                    $thisUserName = $i.Name
                } else {
                    $thisUserName = $i.ToString()
                    Write-Debug "[Get-JiraUser] Username is assumed to be [$thisUserName] via ToString()"
                }

                Write-Debug "[Get-JiraUser] Invoking myself with the UserName parameter set to search for user [$thisUserName]"
                $userObj = Get-JiraUser -UserName $thisUserName -Credential $Credential
                Write-Debug "[Get-JiraUser] Returned from invoking myself; outputting results"
                Write-Output $userObj
            }
        }
    }

    end
    {
        Write-Debug "[Get-JiraUser] Complete"
    }
}


