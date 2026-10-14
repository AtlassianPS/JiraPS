function Test-JiraCloudServer {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param([Parameter(Mandatory)][AtlassianPS.Connection]$RequestContext)
    if (-not $RequestContext.DeploymentType) { throw 'Jira deployment type has not been validated.' }
    $RequestContext.DeploymentType -eq 'Cloud'
}
