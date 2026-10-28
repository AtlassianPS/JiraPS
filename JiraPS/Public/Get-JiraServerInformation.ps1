function Get-JiraServerInformation {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param(
        [Parameter()]
        [Switch]
        $Refresh,

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

        $operation = { Get-JiraServerInformationOperation @operationParameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
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

New-Alias -Name "Get-JiraServerInfo" -Value "Get-JiraServerInformation" -ErrorAction SilentlyContinue
