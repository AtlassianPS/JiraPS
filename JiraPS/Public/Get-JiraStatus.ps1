function Get-JiraStatus {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [Alias('IdOrName')]
        [AtlassianPS.JiraPS.StatusTransformation()]
        [AtlassianPS.JiraPS.Status[]]
        $Status,

        [Parameter()]
        [Switch]
        $Refresh,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceUri = "/rest/api/latest/status"
        $parameter = @{
            URI         = $resourceUri
            Method      = "GET"
            CacheKey    = 'Statuses'
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

                Write-Output (ConvertTo-JiraStatus -InputObject $result)
            }
            '_Search' {
                foreach ($_status in $Status) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_status]"
                    Write-DebugMessage "Processing `$_status [$_status]"

                    $statusIdentifier = if ($null -ne $_status.Id) { [String] $_status.Id }
                    else { $_status.Name }
                    $encodedIdentifier = ConvertTo-URLEncoded -InputString $statusIdentifier

                    $parameter.URI = "$resourceUri/$encodedIdentifier"
                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraStatus -InputObject $result)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
