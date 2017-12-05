function Get-JiraIssue {
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
       This function can accept JiraPS.Issue objects, Strings, or Objects via the pipeline.

       * If a JiraPS.Issue object is passed, this function returns a new reference to the same issue.
        * If a String is passed, this function searches for an issue with that issue key or internal ID.
        * If an Object is passed, this function invokes its ToString() method and treats it as a String.
    .OUTPUTS
       This function outputs the JiraPS.Issue object retrieved.
    .NOTES
        This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByIssueKey')]
    param(
        # Key of the issue to search for.
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByIssueKey' )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Key,

        # Object of an issue to search for.
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Issue" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraIssue',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Issue. Expected [JiraPS.Issue] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else {
                    return $true
                }
            }
        )]
        [Object[]]
        $InputObject,
        <#
          #ToDo:Deprecate
          This is not necessary if $Key uses ValueFromPipelineByPropertyName
          #ToDo:CustomClass
          Once we have custom classes, this check can be done with Type declaration
        #>

        # JQL query for which to search for.
        [Parameter( Mandatory, ParameterSetName = 'ByJQL' )]
        [Alias('JQL')]
        [String]
        $Query,

        # Object of an existing JIRA filter from which the results will be returned.
        [Parameter( Mandatory, ParameterSetName = 'ByFilter' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Filter" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraFilter',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Filter. Expected [JiraPS.Filter] or [String], but was $($_.GetType().Name)"
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
        [Object]
        $Filter,

        # Index of the first issue to return. This can be used to "page" through
        # issues in a large collection or a slow connection.
        [Parameter( ParameterSetName = 'ByJQL' )]
        [Parameter( ParameterSetName = 'ByFilter' )]
        [Int]
        $StartIndex = 0,

        # Maximum number of results to return. By default, all issues will be
        # returned.
        [Parameter( ParameterSetName = 'ByJQL' )]
        [Parameter( ParameterSetName = 'ByFilter' )]
        [Int]
        $MaxResults = 0,

        # How many issues should be returned per call to JIRA. This parameter
        # only has effect if $MaxResults is not provided or set to 0. Normally,
        # you should not need to adjust this parameter, but if the REST calls
        # take a long time, try playing with different values here.
        [Parameter( ParameterSetName = 'ByJQL' )]
        [Parameter( ParameterSetName = 'ByFilter' )]
        [Int]
        $PageSize = 50,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        if (($PSCmdlet.ParameterSetName -in @('ByJQL', 'ByFilter')) -and $MaxResults -eq 0) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Using loop mode to obtain all results"
            $MaxResults = 1
            $loopMode = $true
        }
        else {
            $loopMode = $false
        }

        $resourceURi = "$server/rest/api/latest/issue/{0}?expand=transitions"
        $searchURi = "$server/rest/api/latest/search?jql={0}&validateQuery=true&expand=transitions&startAt={1}&maxResults={2}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            'ByIssueKey' {
                foreach ($_key in $Key) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_key]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_key [$_key]"

                    $parameter = @{
                        URI        = $resourceURi -f $_key
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraIssue -InputObject $result)
                }
            }
            'ByInputObject' {
                Write-Warning "[$($MyInvocation.MyCommand.Name)] The parameter '-InputObject' has been marked as deprecated."
                foreach ($_issue in $InputObject) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issue]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_issue [$_issue]"

                    Write-Output (Get-JiraIssue -Key $_issue.Key -Credential $Credential)
                }
            }
            'ByJQL' {
                $escapedQuery = ConvertTo-URLEncoded $Query

                $parameter = @{
                    URI        = $searchURi -f $escapedQuery, $StartIndex, $MaxResults
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                if ($result) {
                    # {"startAt":0,"maxResults":50,"total":0,"issues":[]}

                    if ($loopMode) {
                        $totalResults = $result.total

                        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Paging through all issues (loop mode)"
                        $allIssues = New-Object -TypeName System.Collections.ArrayList

                        for ($i = 0; $i -lt $totalResults; $i = $i + $PageSize) {
                            $percentComplete = ($i / $totalResults) * 100
                            Write-Progress -Activity "$($MyInvocation.MyCommand.Name)" -Status "Obtaining issues ($i - $($i + $PageSize))..." -PercentComplete $percentComplete

                            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Obtaining issues $i - $($i + $PageSize)..."
                            $thisSection = Get-JiraIssue -Query $Query -StartIndex $i -MaxResults $PageSize -Credential $Credential

                            foreach ($t in $thisSection) {
                                [void] $allIssues.Add($t)
                            }
                        }
                        Write-Progress -Activity "$($MyInvocation.MyCommand.Name)" -Status 'Obtaining issues' -Completed
                        Write-Output ($allIssues.ToArray())
                    }
                    elseif ($result.total -gt 0) {
                        Write-Output (ConvertTo-JiraIssue -InputObject $result.issues)
                    }
                    else {
                        $errorMessage = @{
                            Category         = "ObjectNotFound"
                            CategoryActivity = "Searching for resource"
                            Message          = "The JQL query did not return any results"
                        }
                        Write-Error @errorMessage
                    }
                }
            }
            'ByFilter' {
                $filterObj = Get-JiraFilter -InputObject $Filter -Credential $Credential -ErrorAction Stop
                $jql = $filterObj.JQL
                <#
                  #ToDo:CustomClass
                  Once we have custom classes, this will no longer be necessary
                #>

                # MaxResults would have been set to 1 in the Begin block if it
                # was not supplied as a parameter. We don't want to explicitly
                # invoke this method recursively with a MaxResults value of 1
                # if it wasn't initially provided to us.
                if ($loopMode) {
                    Write-Output (Get-JiraIssue -Query $jql -Credential $Credential)
                }
                else {
                    Write-Output (Get-JiraIssue -Query $jql -Credential $Credential -MaxResults $MaxResults)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
