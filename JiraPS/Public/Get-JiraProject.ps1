function Get-JiraProject {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [AtlassianPS.JiraPS.ProjectTransformation()]
        [AtlassianPS.JiraPS.Project[]]
        $Project,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceURi = "/rest/api/2/project{0}?expand=description,lead,issueTypes,url,projectKeys"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                $parameter = @{
                    URI    = $resourceURi -f ""
                    Method = "GET"
                }
                Write-DebugMessage "Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                Write-Output (ConvertTo-JiraProject -InputObject $result)
            }
            '_Search' {
                foreach ($_project in $Project) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_project]"
                    Write-DebugMessage "Processing `$_project [$_project]"

                    $projectIdentifier = if ($_project.Key) { $_project.Key }
                    else { $_project.Id }

                    $parameter = @{
                        URI    = $resourceURi -f "/$projectIdentifier"
                        Method = "GET"
                    }
                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraProject -InputObject $result)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
