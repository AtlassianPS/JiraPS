function Get-JiraUser {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsPaging, DefaultParameterSetName = 'Self')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = 'User')]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [AtlassianPS.JiraPS.User[]]$User,

        [Parameter(Mandatory, ParameterSetName = 'Query')]
        [ValidateNotNullOrEmpty()]
        [String]$Query,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Switch]$All,

        [Parameter(ParameterSetName = 'Query')]
        [Switch]$IncludeInactive,

        [Parameter(ParameterSetName = 'Query')]
        [Parameter(ParameterSetName = 'All')]
        [ValidateRange(1, 1000)]
        [Int]$PageSize = $script:DefaultPageSize,

        [AtlassianPS.Connection]$Connection
    )

    begin {
        if ($PSCmdlet.ParameterSetName -in @('Self', 'User') -and @('First', 'Skip', 'IncludeTotalCount' | Where-Object { $PSBoundParameters.ContainsKey($_) }).Count) {
            throw 'User paging parameters require -Query or -All.'
        }
        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
        $parameters = @{} + $PSBoundParameters
        $null = $parameters.Remove('Connection')
        $parameters['RequestContext'] = $requestContext
        $operation = { Get-JiraUserOperation @parameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $operation.Begin($PSCmdlet)
    }
    process { $operation.Process($_) }
    end { $operation.End() }
}
