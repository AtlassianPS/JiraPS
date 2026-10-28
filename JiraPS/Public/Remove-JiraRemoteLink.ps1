function Remove-JiraRemoteLink {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = 'High', SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Parameter( Mandatory )]
        [AtlassianPS.JiraPS.LinkTransformation()]
        [AtlassianPS.JiraPS.Link[]]
        $Link,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceURi = "/rest/api/2/issue/{0}/remotelink/{1}"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$Issue]"
        Write-DebugMessage "Processing `$Issue [$Issue]"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

        foreach ($_link in $Link) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_link]"
            Write-DebugMessage "Processing `$_link [$_link]"

            $parameter = @{
                URI    = $resourceURi -f $issueObj.Key, $_link.Id
                Method = "DELETE"
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($issueObj.Key, "Remove RemoteLink '$_link'")) { Invoke-JiraRequest -RequestContext $RequestContext @parameter }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
