
function Set-JiraConfigServer {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][Alias('Uri')][Uri]$Server)

    Write-Warning 'Set-JiraConfigServer is obsolete. Save a named profile and use Connect-Jira -Profile with explicit authentication.'
    $null = Resolve-JiraEndpoint -Uri $Server
    if ($PSCmdlet.ShouldProcess($Server.GetLeftPart('Path'), 'Save legacy Jira endpoint profile')) {
        $existing = AtlassianPS.Configuration\Get-AtlassianServerConfiguration -Name 'JiraPS.LegacyEndpoint'
        if ($existing) {
            AtlassianPS.Configuration\Set-AtlassianServerConfiguration -Id $existing.Id -Uri $Server -Confirm:$false
        }
        else {
            AtlassianPS.Configuration\Add-AtlassianServerConfiguration -Name 'JiraPS.LegacyEndpoint' -Uri $Server -Type Jira -Confirm:$false
        }
        $script:JiraServerUrl = $Server
    }
}
