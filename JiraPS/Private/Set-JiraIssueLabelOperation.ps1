function Set-JiraIssueLabelOperation {
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'ReplaceLabels' )]
    param(
        [Parameter( Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
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

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext,

        [Switch]
        $PassThru
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$Issue]"
        Write-DebugMessage "Processing `$Issue [$Issue]"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

        $labels = [System.Collections.Generic.List[string]]::new(
            [string[]]@($issueObj.labels | Where-Object { $_ })
        )

        # As of JIRA 6.4, the Add and Remove verbs in the REST API for
        # updating issues do not support arrays of parameters - you
        # need to pass a single label to add or remove per API call.

        # Instead, we'll do some fancy footwork with the existing
        # issue object and use the Set verb for everything, so we only
        # have to make one call to JIRA.
        switch ($PSCmdlet.ParameterSetName) {
            'ClearLabels' {
                Write-DebugMessage "Clearing all labels"
                $labels.Clear()
            }
            'ReplaceLabels' {
                Write-DebugMessage "Replacing existing labels"
                $labels = [System.Collections.Generic.List[string]]::new([string[]]$Set)
            }
            'ModifyLabels' {
                if ($Add) {
                    Write-DebugMessage "Adding labels"
                    $Add.ForEach({ $null = $labels.Add($_) })
                }
                if ($Remove) {
                    Write-DebugMessage "Removing labels"
                    # [List[T]].Remove() returns a bool that .ForEach() would
                    # otherwise propagate to the cmdlet's output stream.
                    $Remove.ForEach({ $null = $labels.Remove($_) })
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
            URI    = $issueObj.RestURL
            Method = "PUT"
            Body   = ConvertTo-Json -InputObject $requestBody -Depth 6
        }
        Write-DebugMessage "Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($IssueObj.Key, "Updating Issue labels")) {
            Invoke-JiraRequest -RequestContext $RequestContext @parameter

            if ($PassThru) { Get-JiraIssueOperation -Key $issueObj.Key -RequestContext $RequestContext }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
