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

        $resourceURi = "/rest/api/2/serverInfo"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $parameter = @{
            URI         = $resourceURi
            Method      = "GET"

            CacheKey    = 'ServerInfo'
            CacheExpiry = [TimeSpan]::FromMinutes(5)
            BypassCache = $Refresh
        }
        Write-DebugMessage "Invoking JiraMethod with `$parameter"

        $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter
        Write-Output (ConvertTo-JiraServerInfo -InputObject $result)
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}

New-Alias -Name "Get-JiraServerInfo" -Value "Get-JiraServerInformation" -ErrorAction SilentlyContinue
