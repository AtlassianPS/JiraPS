function Remove-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = 'Medium', SupportsShouldProcess )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [Alias('Id', 'FilterId')]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter[]]
        $Filter,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $filters = foreach ($item in $Filter) {
            if ($item.RestUrl) { $item }
            else {
                Get-JiraFilterOperation -Id $item.Id -RequestContext $RequestContext -ErrorAction Stop
            }
        }

        foreach ($filter in $filters) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$filter]"
            Write-DebugMessage "Processing `$filter [$filter]"

            $parameter = @{
                URI    = $filter.RestURL
                Method = 'DELETE'
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($filter.Name, "Deleting Filter")) { Invoke-JiraRequest -RequestContext $RequestContext @parameter }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
