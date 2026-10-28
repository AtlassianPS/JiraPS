function Remove-JiraIssueLink {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'ByIssueLink' )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'ByIssueLink' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueLinkTransformation(AllowPipelineFallthrough = $true)]
        [AtlassianPS.JiraPS.IssueLink[]]
        $IssueLink,

        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'ByIssue' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation(AllowPipelineFallthrough = $true)]
        [AtlassianPS.JiraPS.Issue[]]
        $Issue,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceURi = "/rest/api/2/issueLink/{0}"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $linksToRemove = switch ($PSCmdlet.ParameterSetName) {
            'ByIssue' {
                foreach ($currentIssue in $Issue) {
                    $resolvedIssue = if ($currentIssue.IssueLinks) { $currentIssue }
                    else {
                        Resolve-JiraIssueObject -InputObject $currentIssue -RequestContext $RequestContext -ErrorAction Stop
                    }

                    foreach ($link in @($resolvedIssue.IssueLinks)) {
                        if ($link) { $link }
                    }
                }
            }
            default { $IssueLink }
        }

        foreach ($link in $linksToRemove) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$link]"
            Write-DebugMessage "Processing `$link [$link]"

            $parameter = @{
                URI    = $resourceURi -f $link.id
                Method = "DELETE"
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($link.id, "Remove IssueLink")) { Invoke-JiraRequest -RequestContext $RequestContext @parameter }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
