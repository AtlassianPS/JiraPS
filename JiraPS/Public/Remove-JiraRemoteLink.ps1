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
        $LinkId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Switch]
        $Force,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        try {
            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $resourceURi = "/rest/api/2/issue/{0}/remotelink/{1}"

            if ($Force) {
                Write-DebugMessage "-Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
                $oldConfirmPreference = $ConfirmPreference
                $ConfirmPreference = 'None'
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
            Write-DebugMessage -BoundParameters $PSBoundParameters

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$Issue]"
            Write-DebugMessage "Processing `$Issue [$Issue]"

            # Find the proper object for the Issue
            $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

            foreach ($_link in $LinkId) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_link]"
                Write-DebugMessage "Processing `$_link [$_link]"

                $parameter = @{
                    URI    = $resourceURi -f $issueObj.Key, $_link.Id
                    Method = "DELETE"
                }
                Write-DebugMessage "Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($issueObj.Key, "Remove RemoteLink '$_link'")) { Invoke-JiraMethod -RequestContext $RequestContext @parameter }
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            if ($Force) {
                Write-DebugMessage "[Remove-JiraGroupMember] Restoring ConfirmPreference to [$oldConfirmPreference]"
                $ConfirmPreference = $oldConfirmPreference
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
