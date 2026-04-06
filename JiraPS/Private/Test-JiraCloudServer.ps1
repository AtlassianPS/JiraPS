function Test-JiraCloudServer {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    (Get-JiraServerInformation -Credential $Credential -ErrorAction SilentlyContinue).DeploymentType -eq 'Cloud'
}
