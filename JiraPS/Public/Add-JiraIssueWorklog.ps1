function Add-JiraIssueWorklog {
    <#
    .Synopsis
       Adds a worklog item to an existing JIRA issue
    .DESCRIPTION
       This function adds a worklog item to an existing issue in JIRA. You can optionally set the visibility of the item (All Users, Developers, or Administrators).
    .EXAMPLE
       Add-JiraIssueWorklog -Comment "Test comment" -Issue "TEST-001" -TimeSpent 60 -DateStarted (Get-Date)
       This example adds a simple worklog item to the issue TEST-001.
    .EXAMPLE
       Get-JiraIssue "TEST-002" | Add-JiraIssueWorklog "Test worklog item from PowerShell" -TimeSpent 60 -DateStarted (Get-Date)
       This example illustrates pipeline use from Get-JiraIssue to Add-JiraIssueWorklog.
    .EXAMPLE
       Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' | % { Add-JiraIssueWorklog "This issue has been cancelled per Vice President's orders." -TimeSpent 60 -DateStarted (Get-Date)}
       This example illustrates logging work on all projects which match a given JQL query. It would be best to validate the query first to make sure the query returns the expected issues!
    .EXAMPLE
       $comment = Get-Process | Format-Jira
       Add-JiraIssueWorklog $c -Issue TEST-003 -TimeSpent 60 -DateStarted (Get-Date)
       This example illustrates adding a comment based on other logic to a JIRA issue.  Note the use of Format-Jira to convert the output of Get-Process into a format that is easily read by users.
    .INPUTS
       This function can accept JiraPS.Issue objects via pipeline.
    .OUTPUTS
       This function outputs the JiraPS.Worklogitem object created.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding( SupportsShouldProcess )]
    param(
        # Worklog item that should be added to JIRA
        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Comment,

        # Issue to receive the new worklog item
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
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
        [Alias('Key')]
        [Object]
        $Issue,

        # Time spent to be logged
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [TimeSpan]
        $TimeSpent,

        # Date/time started to be logged
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [DateTime]
        $DateStarted,

        # Visibility of the comment - should it be publicly visible, viewable to only developers, or only administrators?
        [ValidateSet('All Users', 'Developers', 'Administrators')]
        [String]
        $VisibleRole = 'All Users',

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "{0}/worklog"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

        if (-not $issueObj) {
            $errorMessage = @{
                Category         = "ObjectNotFound"
                CategoryActivity = "Searching for Issue"
                Message          = "Invalid Issue provided."
            }
            Write-Error @errorMessage
        }

        $requestBody = @{
            'comment'   = $Comment
            'started'   = $DateStarted.ToString()
            'timeSpent' = $TimeSpent.TotalSeconds.ToString()
        }

        # If the visible role should be all users, the visibility block shouldn't be passed at
        # all. JIRA returns a 500 Internal Server Error if you try to pass this block with a
        # value of "All Users".
        if ($VisibleRole -ne 'All Users') {
            $requestBody.visibility = @{
                'type'  = 'role'
                'value' = $VisibleRole
            }
        }

        $parameter = @{
            URI        = $resourceURi -f $issueObj.RestURL
            Method     = "POST"
            Body       = ConvertTo-Json -InputObject $requestBody
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($issueObj.Key)) {
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraWorklogitem -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
