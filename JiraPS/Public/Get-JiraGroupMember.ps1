function Get-JiraGroupMember {
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
       [JiraPS.Group] The group to query for members
    .OUTPUTS
       [JiraPS.User[]] Members of the provided group
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
        # Group object of which to display the members.
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Group" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraGroup',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Group. Expected [JiraPS.Group] or [String], but was $($_.GetType().Name)"
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
        [Object[]]
        $Group,

        # Index of the first user to return. This can be used to "page" through
        # users in a large group or a slow connection.
        [ValidateRange(0, [Int]::MaxValue)]
        [Int]
        $StartIndex = 0,

        # Maximum number of results to return. By default, all users will be
        # returned.
        [ValidateRange(0, [Int]::MaxValue)]
        [Int]
        $MaxResults = 0,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        # This is a parameter in Get-JiraIssue, but in testing, JIRA doesn't
        # reliably return more than 50 results at a time.
        $pageSize = 50

        if ($MaxResults -eq 0) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] MaxResults was not specified. Using loop mode to obtain all members."
            $loopMode = $true
        }
        else {
            $loopMode = $false
            if ($MaxResults -gt 50) {
                Write-Warning "JIRA's API may not properly support MaxResults values higher than 50 for this method. If you receive inconsistent results, do not pass the MaxResults parameter to this function to return all results."
            }
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $groupObj = Get-JiraGroup -GroupName $Group -Credential $Credential -ErrorAction Stop

        foreach ($_group in $groupObj) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_group [$_group]"

            if ($loopMode) {
                # Using the Size property of the group object, iterate
                # through all users in a given group.

                $totalResults = $_group.Size
                $allUsers = New-Object -TypeName System.Collections.ArrayList

                for ($i = 0; $i -lt $totalResults; $i = $i + $PageSize) {
                    if ($PageSize -gt ($i + $totalResults)) {
                        $thisPageSize = $totalResults - $i
                    }
                    else {
                        $thisPageSize = $PageSize
                    }
                    $percentComplete = ($i / $totalResults) * 100
                    Write-Progress -Activity "$($MyInvocation.MyCommand.Name)" -Status "Obtaining members ($i - $($i + $thisPageSize) of $totalResults)..." -PercentComplete $percentComplete

                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Obtaining members $i - $($i + $thisPageSize)..."
                    $thisSection = Get-JiraGroupMember -Group $_group -StartIndex $i -MaxResults $thisPageSize -Credential $Credential

                    foreach ($_user in $thisSection) {
                        [void] $allUsers.Add($_user)
                    }
                }

                Write-Progress -Activity "$($MyInvocation.MyCommand.Name)" -Completed
                Write-Output ($allUsers.ToArray())
            }
            else {
                # Since user is an expandable property of the returned
                # group from JIRA, JIRA doesn't use the MaxResults argument
                # found in other REST endpoints.  Instead, we need to pass
                # expand=users[0:15] for users 0-15 (inclusive).
                $parameter = @{
                    URI        = '{0}&expand=users[{1}:{2}]' -f $_group.RestUrl, $StartIndex, ($StartIndex + $MaxResults)
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraGroup -InputObject $result).Member
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
