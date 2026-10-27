function Add-JiraIssueWatcher {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory )]
        [String[]]
        $Watcher,

        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
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

            $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

            $resourceURi = "{0}/watchers"
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            # Find the proper object for the Issue
            $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

            foreach ($_watcher in $Watcher) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_watcher]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_watcher [$_watcher]"

                $watcherBody = if ($isCloud) { ConvertTo-Json -InputObject $_watcher }
                else { '"{0}"' -f $_watcher }
                $parameter = @{
                    URI    = $resourceURi -f $issueObj.RestURL
                    Method = "POST"
                    Body   = $watcherBody
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($issueObj.Key, "Adding user '$_watcher' as watcher.")) { Invoke-JiraMethod -RequestContext $RequestContext @parameter }
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
