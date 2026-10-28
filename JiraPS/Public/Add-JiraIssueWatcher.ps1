function Add-JiraIssueWatcher {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [AtlassianPS.JiraPS.User[]]
        $Watcher,

        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

        $resourceURi = "{0}/watchers"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

        foreach ($_watcher in $Watcher) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_watcher]"
            Write-DebugMessage "Processing `$_watcher [$_watcher]"

            $user = Resolve-JiraUser -InputObject $_watcher -RequestContext $RequestContext -ErrorAction Stop
            $identifier = if ($isCloud) { $user.AccountId } else { $user.Name }
            if (-not $identifier) { throw 'Watcher requires an accountId on Cloud or a username on Data Center.' }
            $watcherBody = ConvertTo-Json -InputObject $identifier
            $parameter = @{
                URI    = $resourceURi -f $issueObj.RestURL
                Method = "POST"
                Body   = $watcherBody
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($issueObj.Key, "Adding user '$_watcher' as watcher.")) { Invoke-JiraRequest -RequestContext $RequestContext @parameter }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
