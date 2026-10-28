function Get-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'ByFilter' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByFilter' )]
        [ValidateNotNull()]
        [Alias('Id')]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter[]]
        $Filter,

        [Parameter( Mandatory, ParameterSetName = 'MyFavorite' )]
        [Alias('Favourite')]
        [Switch]
        $Favorite,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceURi = "/rest/api/2/filter/{0}"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        switch ($PSCmdlet.ParameterSetName) {
            "ByFilter" {
                foreach ($filter in $Filter) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$filter]"
                    Write-DebugMessage "Processing `$filter [$filter]"

                    $parameter = @{
                        URI    = $resourceURi -f $filter.Id
                        Method = "GET"
                    }
                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraFilter -InputObject $result)
                }
            }
            "MyFavorite" {
                $parameter = @{
                    URI    = $resourceURi -f "favourite"
                    Method = "GET"
                }
                Write-DebugMessage "Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                Write-Output (ConvertTo-JiraFilter -InputObject $result)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
