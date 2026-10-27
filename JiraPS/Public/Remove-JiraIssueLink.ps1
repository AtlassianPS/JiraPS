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
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        try {
            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $resourceURi = "/rest/api/2/issueLink/{0}"
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

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
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$link [$link]"

                $parameter = @{
                    URI    = $resourceURi -f $link.id
                    Method = "DELETE"
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($link.id, "Remove IssueLink")) { Invoke-JiraMethod -RequestContext $RequestContext @parameter }
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
