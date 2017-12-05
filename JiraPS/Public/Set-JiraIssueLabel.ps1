function Set-JiraIssueLabel {
    <#
    .Synopsis
        Modifies labels on an existing JIRA issue
    .DESCRIPTION
        This function modifies labels on an existing JIRA issue.  There are
        four supported operations on labels:

        * Add: appends additional labels to the labels that an issue already has
        * Remove: Removes labels from an issue's current labels
        * Set: erases the existing labels on the issue and replaces them with
        the provided values
        * Clear: removes all labels from the issue
    .EXAMPLE
        Set-JiraIssueLabel -Issue TEST-01 -Set 'fixed'
        This example replaces all existing labels on issue TEST-01 with one
        label, "fixed".
    .EXAMPLE
        Get-JiraIssue -Query 'created >= -7d AND reporter in (joeSmith)' | Set-JiraIssueLabel -Add 'enhancement'
        This example adds the "enhancement" label to all issues matching the JQL - in this case,
        all issues created by user joeSmith in the last 7 days.
    .EXAMPLE
        Get-JiraIssue TEST-01 | Set-JiraIssueLabel -Clear
        This example removes all labels from the issue TEST-01.
    .INPUTS
       [JiraPS.Issue[]] The JIRA issue that should be modified
    .OUTPUTS
        If the -PassThru parameter is provided, this function will provide a reference
        to the JIRA issue modified.  Otherwise, this function does not provide output.
    #>
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'ReplaceLabels' )]
    param(
        # Issue key or JiraPS.Issue object returned from Get-JiraIssue
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
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
        [Object[]]
        $Issue,

        # List of labels that will be set to the issue.
        # Any label that was already assigned to the issue will be removed.
        [Parameter( Mandatory, ParameterSetName = 'ReplaceLabels' )]
        [Alias('Label', 'Replace')]
        [String[]]
        $Set,

        # Existing labels to be added.
        [Parameter( ParameterSetName = 'ModifyLabels' )]
        [String[]]
        $Add,

        # Existing labels to be removed.
        [Parameter( ParameterSetName = 'ModifyLabels' )]
        [String[]]
        $Remove,

        # Remove all labels.
        [Parameter( Mandatory, ParameterSetName = 'ClearLabels' )]
        [Switch]
        $Clear,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential,

        # Whether output should be provided after invoking this function.
        [Switch]
        $PassThru
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_issue in $Issue) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issue]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_issue [$_issue]"

            # Find the proper object for the Issue
            $issueObj = Resolve-JiraIssueObject -InputObject $_issue -Credential $Credential

            $labels = [System.Collections.ArrayList]@($issueObj.labels)

            # As of JIRA 6.4, the Add and Remove verbs in the REST API for
            # updating issues do not support arrays of parameters - you
            # need to pass a single label to add or remove per API call.

            # Instead, we'll do some fancy footwork with the existing
            # issue object and use the Set verb for everything, so we only
            # have to make one call to JIRA.
            switch ($PSCmdlet.ParameterSetName) {
                'ClearLabels' {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Clearing all labels"
                    $labels = [System.Collections.ArrayList]@()
                }
                'ReplaceLabels' {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Replacing existing labels"
                    $labels = [System.Collections.ArrayList]$Set
                }
                'ModifyLabels' {
                    if ($Add) {
                        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding labels"
                        $null = $labels.Add($Add)
                    }
                    if ($Remove) {
                        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Removing labels"
                        @($Remove).ForEach(
                            { $labels.Remove($_) }
                        )
                    }
                }
            }

            $requestBody = @{
                'update' = @{
                    'labels' = @(
                        @{
                            'set' = @($labels)
                        }
                    )
                }
            }

            $parameter = @{
                URI        = $issueObj.RestURL
                Method     = "PUT"
                Body       = ConvertTo-Json -InputObject $requestBody -Depth 4
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($IssueObj.Key, "Updating Issue labels")) {
                Invoke-JiraMethod @parameter

                if ($PassThru) {
                    Get-JiraIssue -Key $issueObj.Key -Credential $Credential
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
