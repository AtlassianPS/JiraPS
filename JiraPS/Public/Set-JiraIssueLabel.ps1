function Set-JiraIssueLabel {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'ReplaceLabels' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Issue" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraIssue'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
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

        [Parameter( Mandatory, ParameterSetName = 'ReplaceLabels' )]
        [Alias('Label', 'Replace')]
        [String[]]
        $Set,

        [Parameter( ParameterSetName = 'ModifyLabels' )]
        [String[]]
        $Add,

        [Parameter( ParameterSetName = 'ModifyLabels' )]
        [String[]]
        $Remove,

        [Parameter( Mandatory, ParameterSetName = 'ClearLabels' )]
        [Switch]
        $Clear,

        [Alias("Credential")]
        [psobject]
        $Session,

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
            $issueObj = Resolve-JiraIssueObject -InputObject $_issue -Session $Session

            $labels = [System.Collections.ArrayList]@($issueObj.labels | Where-Object {$_})

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
                        $null = foreach ($_add in $Add) { $labels.Add($_add) }
                    }
                    if ($Remove) {
                        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Removing labels"
                        foreach ($item in $Remove) {
                            $labels.Remove($item)
                        }
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
                Body       = ConvertTo-Json -InputObject $requestBody -Depth 6
                Session    = $Session
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($IssueObj.Key, "Updating Issue labels")) {
                Invoke-JiraMethod @parameter

                if ($PassThru) {
                    Get-JiraIssue -Key $issueObj.Key -Session $Session
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
