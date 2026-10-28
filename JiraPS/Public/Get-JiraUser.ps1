function Get-JiraUser {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'Self' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByUserName' )]
        [AllowEmptyString()]
        [Alias('User', 'Name')]
        [String[]]
        $UserName,

        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByAccountId' )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $AccountId,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [AtlassianPS.JiraPS.User[]]
        $InputObject,

        [Parameter( ParameterSetName = 'ByInputObject' )]
        [Parameter( ParameterSetName = 'ByUserName' )]
        [Parameter( ParameterSetName = 'ByAccountId' )]
        [Switch]
        $Exact,

        [Switch]
        $IncludeInactive,

        [Parameter( ParameterSetName = 'ByUserName' )]
        [Parameter( ParameterSetName = 'ByAccountId' )]
        [ValidateRange(1, 1000)]
        [UInt32]
        $MaxResults = 50,

        [Parameter( ParameterSetName = 'ByUserName' )]
        [Parameter( ParameterSetName = 'ByAccountId' )]
        [ValidateNotNullOrEmpty()]
        [UInt64]
        $Skip = 0,

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
            $operation = { Get-JiraUserOperation @operationParameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
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
