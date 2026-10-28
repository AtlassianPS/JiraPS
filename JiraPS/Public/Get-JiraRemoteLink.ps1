function Get-JiraRemoteLink {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Int]
        $LinkId,

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

            $urlAppendix = if ($LinkId) { "/$LinkId" } else { "" }

            $parameter = @{
                URI    = "{0}/remotelink{1}" -f $issueObj.RestUrl, $urlAppendix
                Method = "GET"
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

            Write-Output (ConvertTo-JiraLink -InputObject $result)
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
