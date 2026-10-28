function New-JiraGroup {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory )]
        [Alias('Name')]
        [String[]]
        $GroupName,

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

            $resourceURi = "/rest/api/2/group"
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
                    $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraGroup -InputObject $result)
                }
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
