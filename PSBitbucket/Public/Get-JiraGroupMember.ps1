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
    .NOTES
       By default, this will return all active users who are members of the
       given group.  For large groups, this can take quite some time.

       To limit the number of group members returned, use
       the MaxResults parameter.  You can also combine this with the
       StartIndex parameter to "page" through results.

       This function does not return inactive users.  This appears to be a
       limitation of JIRA's REST API.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Object] $Group,

        # Index of the first user to return. This can be used to "page" through
        # users in a large group or a slow connection.
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [Int]::MaxValue)]
        [Int] $StartIndex = 0,

        # Maximum number of results to return. By default, all users will be
        # returned.
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [Int]::MaxValue)]
        [Int] $MaxResults = 0,

        # Credentials to use to connect to JIRA. If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        # This is a parameter in Get-JiraIssue, but in testing, JIRA doesn't
        # reliably return more than 50 results at a time.
        $pageSize = 50

        if ($MaxResults -eq 0)
        {
            Write-Debug "[Get-JiraGroupMember] MaxResults was not specified. Using loop mode to obtain all members."
            $loopMode = $true
        } else {
            $loopMode = $false
            if ($MaxResults -gt 50)
            {
                Write-Warning "JIRA's API may not properly support MaxResults values higher than 50 for this method. If you receive inconsistent results, do not pass the MaxResults parameter to this function to return all results."
            }
        }
    }

    process
    {
        Write-Debug "[Get-JiraGroupMember] Obtaining a reference to Jira group [$Group]"
        $groupObj = Get-JiraGroup -GroupName $Group -Credential $Credential

        if ($groupObj)
        {
            foreach ($g in $groupObj)
            {
                if ($loopMode)
                {
                    # Using the Size property of the group object, iterate
                    # through all users in a given group.

                    $totalResults = $g.Size
                    $allUsers = New-Object -TypeName System.Collections.ArrayList
                    Write-Debug "[Get-JiraGroupMember] Paging through all results (loop mode)"

                    for ($i = 0; $i -lt $totalResults; $i = $i + $PageSize)
                    {
                        if ($PageSize -gt ($i + $totalResults))
                        {
                            $thisPageSize = $totalResults - $i
                        } else {
                            $thisPageSize = $PageSize
                        }
                        $percentComplete = ($i / $totalResults) * 100
                        Write-Progress -Activity 'Get-JiraGroupMember' -Status "Obtaining members ($i - $($i + $thisPageSize) of $totalResults)..." -PercentComplete $percentComplete
                        Write-Debug "[Get-JiraGroupMember] Obtaining members $i - $($i + $thisPageSize)..."
                        $thisSection = Get-JiraGroupMember -Group $g -StartIndex $i -MaxResults $thisPageSize -Credential $Credential
                        foreach ($t in $thisSection)
                        {
                            [void] $allUsers.Add($t)
                        }
                    }

                    Write-Progress -Activity 'Get-JiraGroupMember' -Completed
                    Write-Output ($allUsers.ToArray())

                } else {
                    # Since user is an expandable property of the returned
                    # group from JIRA, JIRA doesn't use the MaxResults argument
                    # found in other REST endpoints.  Instead, we need to pass
                    # expand=users[0:15] for users 0-15 (inclusive).
                    $url = '{0}&expand=users[{1}:{2}]' -f $g.RestUrl, $StartIndex, ($StartIndex + $MaxResults)

                    Write-Debug "[Get-JiraGroupMember] Preparing for blastoff!"
                    $groupResult = Invoke-JiraMethod -Method Get -URI $url -Credential $Credential

                    if ($groupResult)
                    {
                        # ConvertTo-JiraGroup contains logic to convert and add
                        # users (group members) to user objects if the members
                        # are returned from JIRA.

                        Write-Debug "[Get-JiraGroupMember] Converting results to PSJira.Group and PSJira.User objects"
                        $groupObjResult = ConvertTo-JiraGroup -InputObject $groupResult

                        Write-Debug "[Get-JiraGroupMember] Outputting group members"
                        Write-Output $groupObjResult.Member
                    } else {
                        # Something is wrong here...we didn't get back a result from JIRA when we *did* get a
                        # valid group from Get-JiraGroup earlier.
                        Write-Warning "A JIRA group could not be found at URL [$url], even though this seems to be a valid group."
                    }
                }
            }
        } else {
            throw "Unable to identify group [$Group]. Use Get-JiraGroup to make sure this is a valid JIRA group."
        }
    }
}


