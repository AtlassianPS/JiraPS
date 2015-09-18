function Get-JiraGroupMember
{
    <#
    .Synopsis
       Returns members of a given group in JIRA
    .DESCRIPTION
       This function returns members of a provided group in JIRA.
    .EXAMPLE
       Get-JiraGroupmember testGroup
       This example returns all members of the JIRA group testGroup.
    .EXAMPLE
       Get-JiraGroup 'Developers' | Get-JiraGroupMember
       This example illustrates the use of the pipeline to return members of
       the Developers group in JIRA.
    .INPUTS
       [PSJira.Group] The group to query for members
    .OUTPUTS
       [PSJira.User[]] Members of the provided group
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Object] $Group,

        # Credentials to use to connect to Jira. If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    process
    {
        Write-Debug "[Get-JiraGroupMember] Obtaining a reference to Jira group [$Group]"
        $groupObj = Get-JiraGroup -GroupName $Group -Credential $Credential

        if ($groupObj)
        {
            foreach ($g in $groupObj)
            {
                Write-Debug "[Get-JiraGroupMember] Asking JIRA for members of group [$g]"
                $url = "$($g.RestUrl)&expand=users"

                Write-Debug "[Get-JiraGroupMember] Preparing for blastoff!"
                $groupResult = Invoke-JiraMethod -Method Get -URI $url -Credential $Credential

                if ($groupResult)
                {
                    # ConvertTo-JiraGroup contains logic to convert and add group members to
                    # group objects if the members are returned from JIRA.

                    Write-Debug "[Get-JiraGroupMember] Converting results to PSJira.Group and PSJira.User objects"
                    $groupObjResult = ConvertTo-JiraGroup -InputObject $groupResult

                    Write-Debug "[Get-JiraGroupMember] Outputting group members"
                    Write-Output $groupObjResult.Member
                } else {
                    # Something is wrong here...we didn't get back a result from JIRA when we *did* get a
                    # valid group from Get-JiraGroup earlier.
                    Write-Warning "Something strange happened when invoking JIRA method Get to URL [$url]"
                }
            }
        } else {
            throw "Unable to identify group [$Group]. Use Get-JiraGroup to make sure this is a valid JIRA group."
        }
    }
}


