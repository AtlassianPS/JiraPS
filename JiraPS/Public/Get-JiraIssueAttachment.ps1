function Get-JiraIssueAttachment {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [String]
        $FileName,

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
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
        $operationParameters = @{} + $PSBoundParameters
        $null = $operationParameters.Remove('Connection')
        $null = $operationParameters.Remove('Credential')
        $operationParameters['RequestContext'] = $requestContext

        try {
            $operation = { Get-JiraIssueAttachmentOperation @operationParameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
            $operation.Begin($PSCmdlet)
        }
        catch {
            if ($requestContext.State -eq 'Standalone') { $requestContext.Dispose() }
            throw
        }
    }

    process {
        try { $operation.Process($_) }
        catch {
            if ($requestContext.State -eq 'Standalone') { $requestContext.Dispose() }
            throw
        }
    }

    end {
        try { $operation.End() }
        finally {
            if ($requestContext.State -eq 'Standalone') { $requestContext.Dispose() }
        }
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
