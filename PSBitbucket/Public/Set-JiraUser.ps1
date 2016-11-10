function Set-JiraUser
{
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
       [PSJira.User[]] The JIRA user that should be modified.
    .OUTPUTS
       If the -PassThru parameter is provided, this function will provide a reference
       to the JIRA user modified.  Otherwise, this function does not provide output.
    .NOTES
       It is currently NOT possible to enable and disable users with this function. JIRA
       does not currently provide this ability via their REST API.

       If you'd like to see this ability added to JIRA and to this module, please vote on
       Atlassian's site for this issue: https://jira.atlassian.com/browse/JRA-37294
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByNamedParameters')]
    param(
        # Username or user object obtained from Get-JiraUser
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('UserName')]
        [Object[]] $User,

        [Parameter(ParameterSetName = 'ByNamedParameters',
                   Mandatory = $false)]
        [String] $DisplayName,

        [Parameter(ParameterSetName = 'ByNamedParameters',
                   Mandatory = $false)]
        [String] $EmailAddress,

        [Parameter(ParameterSetName = 'ByHashtable',
                   Mandatory = $true,
                   Position = 1)]
        [Hashtable] $Property,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential,

        [Switch] $PassThru
    )

    begin
    {
        Write-Debug "[Set-JiraUser] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Set-JiraIssue] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        $updateProps = @{}

        if ($PSCmdlet.ParameterSetName -eq 'ByNamedParameters')
        {
            if (-not ($DisplayName -or $EmailAddress))
            {
                Write-Debug "[Set-JiraIssue] Nothing to do."
                return
            } else {
                Write-Debug "[Set-JiraIssue] Building property hashtable"
                if ($DisplayName)
                {
                    $updateProps.displayName = $DisplayName
                }

                if ($EmailAddress)
                {
                    $updateProps.emailAddress = $EmailAddress
                }
            }
        } else {
            $updateProps = $Property
        }

        Write-Debug "[Set-JiraUser] Building URI for REST call"
        $userUrl = "$server/rest/api/latest/user?username={0}"
    }

    process
    {
        foreach ($u in $User)
        {
            Write-Debug "[Set-JiraUser] Obtaining reference to user [$u]"
            $userObj = Get-JiraUser -InputObject $u -Credential $Credential

            if ($userObj)
            {
                $thisUrl = $userUrl -f $userObj.Name
                Write-Debug "[Set-JiraUser] User URL: [$thisUrl]"

                Write-Debug "Preparing for blastoff!"
                $result = Invoke-JiraMethod -Method Put -URI $thisUrl -Body $updateProps -Credential $Credential
                if ($result)
                {
                    Write-Debug "[Set-JiraUser] JIRA returned results."
                    if ($PassThru)
                    {
                        Write-Debug "[Set-JiraUser] PassThru flag was specified. Invoking Get-JiraUser to get an updated reference to user [$u]"
                        Write-Output (Get-JiraUser -InputObject $u)
                    }
                } else {
                    Write-Debug "[Set-JiraUser] JIRA returned no results to display."
                }
            } else {
                Write-Debug "[Set-JiraUser] Unable to identify user [$u]. Writing error message."
                Write-Error "Unable to identify user [$u]"
            }
        }
    }

    end
    {
        Write-Debug "[Set-JiraUser] Complete"
    }
}


