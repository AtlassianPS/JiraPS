function Get-JiraGroupMember {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsPaging )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.GroupTransformation()]
        [AtlassianPS.JiraPS.Group[]]
        $Group,

        [Switch]
        $IncludeInactive,

        [UInt32]
        $PageSize = $script:DefaultPageSize,

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

        $operation = { Get-JiraGroupMemberOperation @operationParameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
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
