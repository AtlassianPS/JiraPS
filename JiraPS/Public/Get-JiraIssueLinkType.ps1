function Get-JiraIssueLinkType {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ParameterSetName = '_Search' )]
        [ValidateNotNullOrEmpty()]
        [AtlassianPS.JiraPS.IssueLinkTypeTransformation()]
        [AtlassianPS.JiraPS.IssueLinkType]
        $LinkType,

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

        $resourceUri = "/rest/api/2/issueLinkType"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $byId = $LinkType -and $null -ne $LinkType.Id
        $parameter = @{
            URI         = if ($byId) { "$resourceUri/$($LinkType.Id)" } else { $resourceUri }
            Method      = "GET"
            CacheKey    = 'IssueLinkTypes'
            CacheExpiry = [TimeSpan]::FromHours(1)
            BypassCache = $Refresh
        }
        Write-DebugMessage "Invoking JiraMethod with `$parameter"
        $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

        if ($byId) { Write-Output (ConvertTo-JiraIssueLinkType -InputObject $result) }
        else {
            $allLinkTypes = ConvertTo-JiraIssueLinkType -InputObject $result.issueLinkTypes

            if ($LinkType) { Write-Output ($allLinkTypes | Where-Object { $_.Name -like $LinkType.Name }) }
            else { Write-Output $allLinkTypes }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
