function Get-JiraGroup
{
    <#
    .Synopsis
       Returns a group from Jira
    .DESCRIPTION
       This function returns information regarding a specified group from JIRA.

       By default, this function does not display members of the group.  This is JIRA's default
       behavior as well.  To display group members, use Get-JiraGroupMember.
    .EXAMPLE
       Get-JiraGroup -GroupName testGroup -Credential $cred
       Returns information about the group "testGroup"
    .EXAMPLE
       Get-ADUser -filter "Name -like 'John*Smith'" | Select-Object -ExpandProperty samAccountName | Get-JiraUser -Credential $cred
       This example searches Active Directory for the username of John W. Smith, John H. Smith,
       and any other John Smiths, then obtains their JIRA user accounts.
    .INPUTS
       [Object[]] The group to look up in JIRA. This can be a String or a JiraPS.Group object.
    .OUTPUTS
       [JiraPS.Group]
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByGroupName')]
    param(
        # Name of the group
        [Parameter(ParameterSetName = 'ByGroupName',
                   Mandatory = $true,
                   Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [String[]] $GroupName,

        [Parameter(ParameterSetName = 'ByInputObject',
                   Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Object[]] $InputObject,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraGroup] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Get-JiraIssue] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        Write-Debug "[Get-JiraGroup] Building URI for REST call"
        $groupUrl = "$server/rest/api/latest/group?groupname={0}"
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByGroupName')
        {
            foreach ($g in $GroupName)
            {
                Write-Debug "[Get-JiraGroup] Escaping group name [$g]"
                $escapedGroupName = [System.Web.HttpUtility]::UrlPathEncode($g)

                Write-Debug "[Get-JiraGroup] Escaped group name: [$escapedGroupName]"
                $thisUrl = $groupUrl -f $escapedGroupName

                Write-Debug "[Get-JiraGroup] Preparing for blastoff!"
                $result = Invoke-JiraMethod -Method Get -URI $thisUrl -Credential $Credential

                if ($result)
                {
                    Write-Debug "[Get-JiraGroup] Converting results to JiraPS.Group"
                    $obj = ConvertTo-JiraGroup -InputObject $result

                    Write-Debug "[Get-JiraGroup] Outputting results"
                    Write-Output $obj
                } else {
                    Write-Debug "[Get-JiraGroup] No results were returned from JIRA"
                    Write-Verbose "No results were returned from JIRA."
                }
            }
        } else {
            foreach ($i in $InputObject)
            {
                Write-Debug "[Get-JiraGroup] Processing InputObject [$i]"
                if ((Get-Member -InputObject $i).TypeName -eq 'JiraPS.Group')
                {
                    Write-Debug "[Get-JiraGroup] User parameter is a JiraPS.Group object"
                    $thisGroupName = $i.Name
                } else {
                    $thisGroupName = $i.ToString()
                    Write-Debug "[Get-JiraGroup] Username is assumed to be [$thisGroupName] via ToString()"
                }

                Write-Debug "[Get-JiraGroup] Invoking myself with the UserName parameter set to search for user [$thisGroupName]"
                $groupObj = Get-JiraGroup -GroupName $thisGroupName -Credential $Credential
                Write-Debug "[Get-JiraGroup] Returned from invoking myself; outputting results"
                Write-Output $groupObj
            }
        }
    }

    end
    {
        Write-Debug "[Get-JiraGroup] Complete"
    }
}


