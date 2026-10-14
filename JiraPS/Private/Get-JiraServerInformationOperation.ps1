function Get-JiraServerInformationOperation {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext,

        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/serverInfo"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

        $parameter = @{
            URI         = $resourceURi
            Method      = "GET"

            CacheKey    = 'ServerInfo'
            CacheExpiry = [TimeSpan]::FromMinutes(5)
            BypassCache = $Force
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

        $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter
        Write-Output (ConvertTo-JiraServerInfo -InputObject $result)
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}

New-Alias -Name "Get-JiraServerInfo" -Value "Get-JiraServerInformation" -ErrorAction SilentlyContinue
