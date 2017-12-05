function Add-JiraIssueWatcher {
    <#
    .Synopsis
       Adds a watcher to an existing JIRA issue
    .DESCRIPTION
       This function adds a watcher to an existing issue in JIRA.
    .EXAMPLE
       Add-JiraIssueWatcher -Watcher "fred" -Issue "TEST-001"
       This example adds a watcher to the issue TEST-001.
    .EXAMPLE
       Get-JiraIssue "TEST-002" | Add-JiraIssueWatcher "fred"
       This example illustrates pipeline use from Get-JiraIssue to Add-JiraIssueWatcher.
    .EXAMPLE
       Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' | % { Add-JiraIssueWatcher "fred" }
       This example illustrates adding watcher on all projects which match a given JQL query. It would be best to validate the query first to make sure the query returns the expected issues!
    .INPUTS
       This function can accept JiraPS.Issue objects via pipeline.
    .OUTPUTS
       This function does not provide output.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding( SupportsShouldProcess )]
    param(
        # Watcher that should be added to JIRA
        [Parameter( Mandatory )]
        [String[]]
        $Watcher,
        <#
          #ToDo:CustomClass
          Once we have custom classes, this can also accept ValueFromPipeline
        #>

        # Issue that should be watched
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

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "{0}/watchers"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

        foreach ($_watcher in $Watcher) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_watcher]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_watcher [$_watcher]"

            $parameter = @{
                URI        = $resourceURi -f $issueObj.RestURL
                Method     = "POST"
                Body       = '"{0}"' -f $_watcher
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($issueObj.Key, "Adding user '$_watcher' as watcher.")) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
