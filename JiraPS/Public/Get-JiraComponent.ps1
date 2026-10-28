function Get-JiraComponent {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'ByID' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByProject' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.ProjectTransformation()]
        [AtlassianPS.JiraPS.Project[]]
        $Project,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByID' )]
        [Alias("Id")]
        [Int[]]
        $ComponentId,

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

            $resourceURi = "/rest/api/2{0}"
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

            switch ($PSCmdlet.ParameterSetName) {
                "ByProject" {
                    foreach ($_project in $Project) {
                        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_project]"
                        Write-DebugMessage "Processing `$_project [$_project]"

                        # The /project/{projectIdOrKey}/components endpoint accepts
                        # either a project key or a numeric ID, so we forward whichever
                        # the typed parameter has populated.
                        $projectIdent = if ($_project.Key) { $_project.Key } else { $_project.ID }

                        $parameter = @{
                            URI    = $resourceURi -f "/project/$projectIdent/components"
                            Method = "GET"
                        }
                        Write-DebugMessage "Invoking JiraMethod with `$parameter"
                        $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                        Write-Output (ConvertTo-JiraComponent -InputObject $result)
                    }
                }
                "ByID" {
                    foreach ($_id in $ComponentId) {
                        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                        Write-DebugMessage "Processing `$_id [$_id]"

                        $parameter = @{
                            URI    = $resourceURi -f "/component/$_id"
                            Method = "GET"
                        }
                        Write-DebugMessage "Invoking JiraMethod with `$parameter"
                        $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                        Write-Output (ConvertTo-JiraComponent -InputObject $result)
                    }
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
