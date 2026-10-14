
function Get-JiraConfigServer {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param()
    $default = Get-JiraConnection -Default
    if ($default) { return $default.BaseUri.AbsoluteUri.TrimEnd('/') }
    $profile = AtlassianPS.Configuration\Get-AtlassianServerConfiguration -Name 'JiraPS.LegacyEndpoint'
    if ($profile -and $profile.Type -eq 'Jira') { return $profile.Uri.AbsoluteUri.TrimEnd('/') }
    if ($script:JiraServerUrl) { return $script:JiraServerUrl.AbsoluteUri.TrimEnd('/') }
}
