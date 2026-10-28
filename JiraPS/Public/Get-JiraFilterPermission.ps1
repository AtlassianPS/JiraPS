function Get-JiraFilterPermission {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [Alias('Id')]
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

        $resourceURi = "{0}/permission"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $filters = foreach ($item in $Filter) {
            if ($item.RestUrl) { $item }
            else {
                Get-JiraFilter -Id $item.Id -Connection $RequestContext -ErrorAction Stop
            }
        }

        foreach ($_filter in $filters) {
            $parameter = @{
                URI    = $resourceURi -f $_filter.RestURL
                Method = "GET"
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

            ConvertTo-JiraFilterPermission -InputObject $result
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
