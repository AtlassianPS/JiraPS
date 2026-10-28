function Get-JiraIssue {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsPaging, DefaultParameterSetName = 'Issue' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Issue' )]
        [ValidateNotNull()]
        [Alias('Key', 'Id')]
        [AtlassianPS.JiraPS.IssueTransformation(AllowCollection = $true, AllowPipelineFallthrough = $true)]
        [AtlassianPS.JiraPS.Issue[]]
        $Issue,

        [Parameter( Mandatory, ParameterSetName = 'ByJQL' )]
        [Alias('JQL')]
        [String]
        $Query,

        [Parameter( Mandatory, ParameterSetName = 'ByFilter' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter]
        $Filter,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Fields = "*all",

        [Parameter( ParameterSetName = 'ByJQL' )]
        [Parameter( ParameterSetName = 'ByFilter' )]
        [UInt32]
        $PageSize = $script:DefaultPageSize,

        [Parameter()]
        [Alias('GetHistory')]
        [Switch]
        $IncludeHistory,

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

        $operation = { Get-JiraIssueOperation @operationParameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
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
