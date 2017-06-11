function Get-JiraIssue
{
    <#
    .Synopsis
        Returns information about an issue in JIRA.
    .DESCRIPTION
        This function obtains references to issues in JIRA.

        This function can be used to directly query JIRA for a specific issue key or internal issue ID. It can also be used to query JIRA for issues matching a specific criteria using JQL (Jira Query Language).

        For more details on JQL syntax, see this articla from Atlassian: https://confluence.atlassian.com/display/JIRA/Advanced+Searching

        Output from this function can be piped to various other functions in this module, including Set-JiraIssue, Add-JiraIssueComment, and Invoke-JiraIssueTransition.
    .EXAMPLE
        Get-JiraIssue -Key TEST-001
        This example returns a reference to JIRA issue TEST-001.
    .EXAMPLE
        Get-JiraIssue "TEST-002" | Add-JiraIssueComment "Test comment from PowerShell"
        This example illustrates pipeline use from Get-JiraIssue to Add-JiraIssueComment.
    .EXAMPLE
        Get-JiraIssue -Query 'project = "TEST" AND created >= -5d'
        This example illustrates using the Query parameter and JQL syntax to query Jira for matching issues.
    .EXAMPLE
        Get-JiraIssue -InputObject $oldIssue
        This example illustrates how to get an update of an issue from an old result of Get-JiraIssue stored in $oldIssue.
    .EXAMPLE
        Get-JiraFilter -Id 12345 | Get-JiraIssue
        This example retrieves all issues that match the criteria in the saved fiilter with id 12345.
    .INPUTS
        This function can accept PSJira.Issue objects, Strings, or Objects via the pipeline.

        * If a PSJira.Issue object is passed, this function returns a new reference to the same issue.
        * If a String is passed, this function searches for an issue with that issue key or internal ID.
        * If an Object is passed, this function invokes its ToString() method and treats it as a String.
    .OUTPUTS
        This function outputs the PSJira.Issue object retrieved.
    .NOTES
        This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByIssueKey')]
    param(
        # Key of the issue to search for.
        [Parameter(ParameterSetName = 'ByIssueKey',
            Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Key,

        # Object of an issue to search for.
        [Parameter(ParameterSetName = 'ByInputObject',
            Mandatory = $true,
            Position = 0)]
        [Object[]] $InputObject,

        # JQL query for which to search for.
        [Parameter(ParameterSetName = 'ByJQL',
            Mandatory = $true)]
        [Alias('JQL')]
        [String] $Query,

        # Object of an existing JIRA filter from which the results will be returned.
        [Parameter(ParameterSetName = 'ByFilter')]
        [Object] $Filter,

        # Index of the first issue to return. This can be used to "page" through
        # issues in a large collection or a slow connection.
        [Parameter(ParameterSetName = 'ByJQL')]
        [Parameter(ParameterSetName = 'ByFilter')]
        [Int] $StartIndex = 0,

        # Maximum number of results to return. By default, all issues will be
        # returned.
        [Parameter(ParameterSetName = 'ByJQL')]
        [Parameter(ParameterSetName = 'ByFilter')]
        [Int] $MaxResults = 0,

        # How many issues should be returned per call to JIRA. This parameter
        # only has effect if $MaxResults is not provided or set to 0. Normally,
        # you should not need to adjust this parameter, but if the REST calls
        # take a long time, try playing with different values here.
        [Parameter(ParameterSetName = 'ByJQL')]
        [Parameter(ParameterSetName = 'ByFilter')]
        [Int] $PageSize = 50,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraIssue] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Get-JiraIssue] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        $psName = $PSCmdlet.ParameterSetName

        if (($psName -eq 'ByJQL' -or $psName -eq 'ByFilter') -and $MaxResults -eq 0)
        {
            Write-Debug "[Get-JiraIssue] Using loop mode to obtain all results"
            $MaxResults = 1
            $loopMode = $true
        }
        else
        {
            $loopMode = $false
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByIssueKey')
        {
            foreach ($k in $Key)
            {
                Write-Debug "[Get-JiraIssue] Processing issue key [$k]"
                $issueURL = "$($server)/rest/api/latest/issue/${k}?expand=transitions"

                Write-Debug "[Get-JiraIssue] Preparing for blastoff!"
                $result = Invoke-JiraMethod -Method Get -URI $issueURL -Credential $Credential

                if ($result)
                {
                    Write-Debug "[Get-JiraIssue] Converting REST result to Jira object"
                    $obj = ConvertTo-JiraIssue -InputObject $result

                    Write-Debug "[Get-JiraIssue] Outputting result"
                    Write-Output $obj
                }
                else
                {
                    Write-Debug "[Get-JiraIssue] Invoke-JiraMethod returned no results to output."
                }
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByInputObject')
        {
            foreach ($i in $InputObject)
            {
                Write-Debug "[Get-JiraIssue] Processing InputObject [$i]"
                if ((Get-Member -InputObject $i).TypeName -eq 'PSJira.Issue')
                {
                    Write-Debug "[Get-JiraIssue] Issue parameter is a PSJira.Issue object"
                    $issueKey = $i.Key
                }
                else
                {
                    $issueKey = $i.ToString()
                    Write-Debug "[Get-JiraIssue] Issue key is assumed to be [$issueKey] via ToString()"
                }

                Write-Debug "[Get-JiraIssue] Invoking myself with the Key parameter set to search for issue [$issueKey]"
                $issueObj = Get-JiraIssue -Key $issueKey -Credential $Credential
                Write-Debug "[Get-JiraIssue] Returned from invoking myself; outputting results"
                Write-Output $issueObj
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByJQL')
        {

            Write-Debug "[Get-JiraIssue] Escaping query and building URL"
            $escapedQuery = [System.Web.HttpUtility]::UrlPathEncode($Query)
            $issueURL = "$($server)/rest/api/latest/search?jql=$escapedQuery&validateQuery=true&expand=transitions&startAt=$StartIndex&maxResults=$MaxResults"

            Write-Debug "[Get-JiraIssue] Preparing for blastoff!"
            $result = Invoke-JiraMethod -Method Get -URI $issueURL -Credential $Credential

            if ($result)
            {
                # {"startAt":0,"maxResults":50,"total":0,"issues":[]}

                if ($loopMode)
                {
                    $totalResults = $result.total

                    Write-Debug "[Get-JiraIssue] Paging through all issues (loop mode)"
                    $allIssues = New-Object -TypeName System.Collections.ArrayList

                    for ($i = 0; $i -lt $totalResults; $i = $i + $PageSize)
                    {
                        $percentComplete = ($i / $totalResults) * 100
                        Write-Progress -Activity 'Get-JiraIssue' -Status "Obtaining issues ($i - $($i + $PageSize))..." -PercentComplete $percentComplete
                        Write-Debug "[Get-JiraIssue] Obtaining issues $i - $($i + $PageSize)..."
                        $thisSection = Get-JiraIssue -Query $Query -StartIndex $i -MaxResults $PageSize -Credential $Credential
                        foreach ($t in $thisSection)
                        {
                            [void] $allIssues.Add($t)
                        }
                    }
                    Write-Progress -Activity 'Get-JiraIssue' -Status 'Obtaining issues' -Completed
                    Write-Output ($allIssues.ToArray())
                }
                elseif ($result.total -gt 0)
                {
                    Write-Debug "[Get-JiraIssue] Converting REST result to Jira issue"
                    $obj = ConvertTo-JiraIssue -InputObject $result.issues

                    Write-Debug "[Get-JiraIssue] Outputting result"
                    Write-Output $obj
                }
                else
                {
                    Write-Debug "[Get-JiraIssue] No results were found for the specified query"
                    Write-Verbose "No results were found for the query [$Query]"
                }
            }
            else
            {
                Write-Debug "[Get-JiraIssue] Invoke-JiraMethod returned no results"
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByFilter')
        {
            $filterObj = Get-JiraFilter -InputObject $Filter -Credential $Credential
            if ($filterObj)
            {
                $jql = $filterObj.JQL
                Write-Debug "[Get-JiraIssue] Invoking myself with filter JQL: [$jql]"

                # MaxResults would have been set to 1 in the Begin block if it
                # was not supplied as a parameter. We don't want to explicitly
                # invoke this method recursively with a MaxResults value of 1
                # if it wasn't initially provided to us.
                if ($loopMode)
                {
                    $result = Get-JiraIssue -Query $jql -Credential $Credential
                }
                else
                {
                    $result = Get-JiraIssue -Query $jql -Credential $Credential -MaxResults $MaxResults
                }
                if ($result)
                {
                    Write-Debug "[Get-JiraIssue] Returned from invoking myself; outputting results"
                    Write-Output $result
                }
                else
                {
                    Write-Debug "[Get-JiraIssue] Returned from invoking myself, but no results were found"
                }
            }
            else
            {
                Write-Debug "[Get-JiraIssue] Unable to identify filter [$Filter]"
                Write-Error "Unable to identify filter [$Filter]. Check Get-JiraFilter for more details."
            }
        }
    }

    end
    {
        Write-Debug "[Get-JiraIssue] Complete"
    }
}
