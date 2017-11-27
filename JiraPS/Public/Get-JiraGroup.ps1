function Get-JiraGroup {
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
    [CmdletBinding()]
    param(
        # Name of the group to search for.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [String[]] $GroupName,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/group?groupname={0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($group in $GroupName) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing filterId [${group}]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing filterId [${group}]"

            $escapedGroupName = [System.Web.HttpUtility]::UrlPathEncode($group)

            $parameter = @{
                URI = $resourceURi -f $escapedGroupName
                Method = "GET"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraGroup -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
