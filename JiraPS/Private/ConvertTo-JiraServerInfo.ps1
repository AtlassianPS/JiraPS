function ConvertTo-JiraServerInfo {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.ServerInfo])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.ServerInfo"

            $hash = @{
                BaseURL        = $i.baseUrl
                Version        = $i.version
                DeploymentType = if ($i.deploymentType) { $i.deploymentType } else { 'Server' }
                BuildNumber    = $i.buildNumber
                BuildDate      = if ($i.buildDate) { Get-Date $i.buildDate } else { $null }
                ServerTime     = if ($i.serverTime) { Get-Date $i.serverTime } else { $null }
                ScmInfo        = $i.scmInfo
                ServerTitle    = $i.serverTitle
                DisplayUrl     = $i.displayUrl
            }

            if ($i.versionNumbers) {
                $hash.VersionNumbers = [int[]]@($i.versionNumbers)
            }

            [AtlassianPS.JiraPS.ServerInfo]$hash
        }
    }
}
