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
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        try {
            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $resourceURi = "{0}/permission"
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
            Write-DebugMessage -BoundParameters $PSBoundParameters

            $filters = foreach ($item in $Filter) {
                if ($item.RestUrl) { $item }
                else {
                    Get-JiraFilterOperation -Id $item.Id -RequestContext $RequestContext -ErrorAction Stop
                }
            }

            foreach ($_filter in $filters) {
                $parameter = @{
                    URI    = $resourceURi -f $_filter.RestURL
                    Method = "GET"
                }
                Write-DebugMessage "Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                Write-Output (ConvertTo-JiraFilter -InputObject $_filter -FilterPermissions $result)
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
