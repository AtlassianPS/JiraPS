function New-JiraGroup {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory )]
        [Alias('Name')]
        [String[]]
        $GroupName,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceURi = "/rest/api/2/group"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        foreach ($_group in $GroupName) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-DebugMessage "Processing `$_group [$_group]"

            $requestBody = @{
                "name" = $_group
            }

            $parameter = @{
                URI    = $resourceURi
                Method = "POST"
                Body   = ConvertTo-Json -InputObject $requestBody
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($GroupName, "Creating group [$GroupName] to JIRA")) {
                $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                Write-Output (ConvertTo-JiraGroup -InputObject $result)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
