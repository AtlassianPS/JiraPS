function Test-JiraCloudServer {
    [CmdletBinding()]
    [OutputType( [Boolean] )]
    param(
        [Parameter( Mandatory )]
        [AtlassianPS.Connection]
        $RequestContext
    )

    $RequestContext.DeploymentType -eq 'Cloud'
}
