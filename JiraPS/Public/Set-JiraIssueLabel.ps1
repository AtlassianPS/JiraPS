function Set-JiraIssueLabel {
    # .ExternalHelp ..\JiraPS-help.xml
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
        [Switch]
        $PassThru,

        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PSCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $issueObject = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $requestContext
        $labels = [System.Collections.Generic.List[string]]::new(
            [string[]]@($issueObject.Labels | Where-Object { $_ })
        )

        switch ($PSCmdlet.ParameterSetName) {
            'ClearLabels' { $labels.Clear() }
            'ReplaceLabels' { $labels = [System.Collections.Generic.List[string]]::new([string[]]$Set) }
            'ModifyLabels' {
                foreach ($label in $Add) { $labels.Add($label) }
                foreach ($label in $Remove) { $null = $labels.Remove($label) }
            }
        }

        # A single set operation works across Jira versions that cannot add or remove label arrays.
        $parameter = @{
            URI    = $issueObject.RestUrl
            Method = 'PUT'
            Body   = ConvertTo-Json -InputObject @{ update = @{ labels = @(@{ set = @($labels) }) } } -Depth 6
        }
        if ($PSCmdlet.ShouldProcess($issueObject.Key, 'Updating Issue labels')) {
            Invoke-JiraRequest -RequestContext $requestContext @parameter
            if ($PassThru) { Get-JiraIssueOperation -Key $issueObject.Key -RequestContext $requestContext }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
