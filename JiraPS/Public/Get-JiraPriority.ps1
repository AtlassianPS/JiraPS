function Get-JiraPriority {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [Int[]]
        $Id,

        [Parameter()]
        [Switch]
        $Refresh,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceUri = "/rest/api/2/priority"
        $parameter = @{
            URI         = $resourceUri
            Method      = "GET"
            CacheKey    = 'Priorities'
            CacheExpiry = [TimeSpan]::FromHours(1)
            BypassCache = $Refresh
        }
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                Write-DebugMessage "Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                Write-Output (ConvertTo-JiraPriority -InputObject $result)
            }
            '_Search' {
                foreach ($_id in $Id) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                    Write-DebugMessage "Processing `$_id [$_id]"

                    $parameter.URI = "$resourceUri/$_id"
                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraPriority -InputObject $result)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
