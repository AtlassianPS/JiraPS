function Get-JiraIssueCreateMetadata {
    # .ExternalHelp ..\JiraPS-help.xml
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '')]
    [CmdletBinding( SupportsPaging )]
    param(
        [Parameter( Mandatory )]
        [AtlassianPS.JiraPS.ProjectTransformation()]
        [AtlassianPS.JiraPS.Project]
        $Project,

        [Parameter( Mandatory )]
        [AtlassianPS.JiraPS.IssueTypeTransformation()]
        [AtlassianPS.JiraPS.IssueType]
        $IssueType,

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

        $operation = { Get-JiraIssueCreateMetadataOperation @operationParameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
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
