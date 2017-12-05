function Remove-JiraIssueWatcher {
    <#
    .Synopsis
       Removes a watcher from an existing JIRA issue
    .DESCRIPTION
       This function removes a watcher from an existing issue in JIRA.
    .EXAMPLE
       Remove-JiraIssueWatcher -Watcher "fred" -Issue "TEST-001"
       This example removes a watcher from the issue TEST-001.
    .EXAMPLE
       Get-JiraIssue "TEST-002" | Remove-JiraIssueWatcher "fred"
       This example illustrates pipeline use from Get-JiraIssue to Remove-JiraIssueWatcher.
    .EXAMPLE
       Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' | % { Remove-JiraIssueWatcher "fred" }
       This example illustrates removing watcher on all projects which match a given JQL query. It would be best to validate the query first to make sure the query returns the expected issues!
    .INPUTS
       This function can accept JiraPS.Issue objects via pipeline.
    .OUTPUTS
       This function does not provide output.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding( SupportsShouldProcess )]
    param(
        # Watcher that should be removed from JIRA
        [Parameter( Mandatory )]
        [string[]]
        $Watcher,

        # Issue that should be updated
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [Alias('Key')]
        [Object]
        $Issue,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

        foreach ($username in $Watcher) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$username]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$username [$username]"

            $parameter = @{
                URI        = "{0}/watchers?username={1}" -f $issueObj.RestURL, $username
                Method     = "DELETE"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($IssueObj.Key, "Removing watcher '$($username)'")) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
