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
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceURi = "/rest/api/2/issueLinkType{0}"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        if ($LinkType -and $LinkType.Id) {
            $parameter = @{
                URI    = $resourceURi -f "/$($LinkType.Id)"
                Method = "GET"
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

            Write-Output (ConvertTo-JiraIssueLinkType -InputObject $result)
        }
        else {
            $parameter = @{
                URI    = $resourceURi -f ""
                Method = "GET"
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter
            $allLinkTypes = ConvertTo-JiraIssueLinkType -InputObject $result.issueLinkTypes

            if ($LinkType) { Write-Output ($allLinkTypes | Where-Object { $_.Name -like $LinkType.Name }) }
            else { Write-Output $allLinkTypes }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
