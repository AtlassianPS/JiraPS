function Get-JiraFilterOperation {
    [CmdletBinding( DefaultParameterSetName = 'ByInputObject' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNull()]
        [Alias('Id')]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter[]]
        $InputObject,

        [Parameter( Mandatory, ParameterSetName = 'MyFavorite' )]
        [Alias('Favourite')]
        [Switch]
        $Favorite,

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/filter/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

        switch ($PSCmdlet.ParameterSetName) {
            "ByInputObject" {
                foreach ($filter in $InputObject) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$filter]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$filter [$filter]"

                    $parameter = @{
                        URI    = $resourceURi -f $filter.Id
                        Method = "GET"

                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraFilter -InputObject $result)
                }
            }
            "MyFavorite" {
                $parameter = @{
                    URI    = $resourceURi -f "favourite"
                    Method = "GET"

                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                Write-Output (ConvertTo-JiraFilter -InputObject $result)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
