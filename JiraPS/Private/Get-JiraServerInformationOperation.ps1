function Get-JiraServerInformationOperation {
    <#
    .SYNOPSIS
        Retrieve cached deployment metadata from the selected Jira endpoint.
    .DESCRIPTION
        Refresh fetches a new response and replaces the connection-scoped cache entry.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext,

        [Switch]
        $Refresh
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

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
