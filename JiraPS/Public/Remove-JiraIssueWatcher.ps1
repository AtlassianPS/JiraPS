function Remove-JiraIssueWatcher {
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
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

        foreach ($watcherValue in $Watcher) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$watcherValue]"
            Write-DebugMessage "Processing `$watcherValue [$watcherValue]"

            $user = Resolve-JiraUser -InputObject $watcherValue -RequestContext $RequestContext -ErrorAction Stop
            $identifier = if ($isCloud) { $user.AccountId } else { $user.Name }
            if (-not $identifier) { throw 'Watcher requires an accountId on Cloud or a username on Data Center.' }
            $queryParameters = if ($isCloud) { @{ accountId = $identifier } } else { @{ username = $identifier } }
            $parameter = @{
                URI          = "{0}/watchers" -f $issueObj.RestURL
                Method       = "DELETE"
                GetParameter = $queryParameters
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($IssueObj.Key, "Removing watcher '$($watcherValue)'")) { Invoke-JiraRequest -RequestContext $RequestContext @parameter }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
