function Add-JiraIssueComment {
    <#
    .Synopsis
       Adds a comment to an existing JIRA issue
    .DESCRIPTION
       This function adds a comment to an existing issue in JIRA. You can optionally set the visibility of the comment (All Users, Developers, or Administrators).
    .EXAMPLE
       Add-JiraIssueComment -Comment "Test comment" -Issue "TEST-001"
       This example adds a simple comment to the issue TEST-001.
    .EXAMPLE
       Get-JiraIssue "TEST-002" | Add-JiraIssueComment "Test comment from PowerShell"
       This example illustrates pipeline use from Get-JiraIssue to Add-JiraIssueComment.
    .EXAMPLE
       Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' | % { Add-JiraIssueComment "This issue has been cancelled per Vice President's orders." }
       This example illustrates commenting on all projects which match a given JQL query. It would be best to validate the query first to make sure the query returns the expected issues!
    .EXAMPLE
       $comment = Get-Process | Format-Jira
       Add-JiraIssueComment $c -Issue TEST-003
       This example illustrates adding a comment based on other logic to a JIRA issue.  Note the use of Format-Jira to convert the output of Get-Process into a format that is easily read by users.
    .INPUTS
       This function can accept JiraPS.Issue objects via pipeline.
    .OUTPUTS
       This function outputs the JiraPS.Comment object created.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding( SupportsShouldProcess )]
    param(
        # Comment that should be added to JIRA.
        [Parameter( Mandatory )]
        [String]
        $Comment,

        # Issue that should be commented upon.
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [Alias('Key')]
        [Object]
        $Issue,

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

        $resourceURi = "{0}/comment"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

        $requestBody = @{
            'body' = $Comment
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
            $rawResult = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraComment -InputObject $rawResult)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
