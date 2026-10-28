function Get-JiraField {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [AtlassianPS.JiraPS.FieldTransformation()]
        [AtlassianPS.JiraPS.Field[]]
        $Field,

        [Parameter()]
        [switch]
        $Refresh,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceURi = "/rest/api/2/field"
        $allFields = $null
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        if ($null -eq $allFields) {
            $parameter = @{
                URI         = $resourceURi
                Method      = "GET"
                CacheKey    = 'Fields'
                CacheExpiry = [TimeSpan]::FromHours(1)
                BypassCache = $Refresh
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter
            $allFields = @(ConvertTo-JiraField -InputObject $result)
        }

        if ($PSCmdlet.ParameterSetName -eq '_All') { Write-Output $allFields }
        else {
            foreach ($_field in $Field) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_field]"
                Write-DebugMessage "Processing `$_field [$_field]"

                $matchesById = @($allFields | Where-Object -FilterScript { $_field.Id -and $_.Id -eq $_field.Id })
                if ($matchesById.Count -gt 0 -or ($_field.Id -and $_field.Name)) { Write-Output $matchesById }
                else {
                    $pattern = if ($_field.Name) { $_field.Name } else { $_field.Id }
                    $allFields | Where-Object -FilterScript { $_.Name -like $pattern }
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
