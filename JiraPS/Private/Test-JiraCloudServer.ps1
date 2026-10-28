function Test-JiraCloudServer {
    <#
    .SYNOPSIS
        Report whether a request context has validated Cloud deployment metadata.
    #>
    [CmdletBinding()]
    [OutputType( [Boolean] )]
    param(
        [Parameter( Mandatory )]
        [AtlassianPS.Connection]
        $RequestContext
    )

    $RequestContext.DeploymentType -eq 'Cloud'
}
