function Get-JiraVersion {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsPaging, DefaultParameterSetName = 'Version')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = 'Version')]
        [ValidateNotNull()]
        [Alias('Id')]
        [AtlassianPS.JiraPS.VersionTransformation(AllowPipelineFallthrough = $true)]
        [AtlassianPS.JiraPS.Version[]]$Version,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Project')]
        [ValidateNotNull()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.ProjectTransformation(AllowPipelineFallthrough = $true)]
        [AtlassianPS.JiraPS.Project[]]$Project,

        [Parameter(ParameterSetName = 'Project')]
        [String[]]$Name = '*',

        [Parameter(ParameterSetName = 'Project')]
        [ValidateSet('sequence', 'name', 'startDate', 'releaseDate')]
        [String]$Sort = 'name',

        [ValidateRange(1, [int]::MaxValue)]
        [Int]$PageSize = $script:DefaultPageSize,

        [AtlassianPS.Connection]$Connection
    )

    begin {
        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
        $parameters = @{} + $PSBoundParameters
        $null = $parameters.Remove('Connection')
        $parameters['RequestContext'] = $requestContext
        $operation = { Get-JiraVersionOperation @parameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $operation.Begin($PSCmdlet)
    }
    process { $operation.Process($_) }
    end { $operation.End() }
}
