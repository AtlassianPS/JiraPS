function Get-JiraIssueEditMetadata {
    # .ExternalHelp ..\JiraPS-help.xml
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
        $operationParameters = @{} + $PSBoundParameters
        $null = $operationParameters.Remove('Connection')
        $operationParameters['RequestContext'] = $requestContext

        $operation = { Get-JiraIssueEditMetadataOperation @operationParameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $operation.Begin($PSCmdlet)
    }

    process {
        $operation.Process($_)
    }

    end {
        $operation.End()
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
