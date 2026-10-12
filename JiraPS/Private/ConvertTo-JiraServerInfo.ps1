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
            if ($null -eq $i) { continue }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.ServerInfo"

            $hash = @{
                BaseURL                         = [uri]$i.baseUrl
                Version                         = $i.version
                DeploymentType                  = [AtlassianPS.JiraPS.DeploymentType]::Server
                BuildNumber                     = $i.buildNumber
                BuildDate                       = ConvertTo-JiraDateTimeOffsetValue $i.buildDate
                ServerTime                      = ConvertTo-JiraDateTimeOffsetValue $i.serverTime
                ScmInfo                         = $i.scmInfo
                ServerTitle                     = $i.serverTitle
                DisplayUrl                      = [uri]$i.displayUrl
                DisplayUrlConfluence            = [uri]$i.displayUrlConfluence
                DisplayUrlServicedeskHelpCenter = [uri]$i.displayUrlServicedeskHelpCenter
                BuildPartnerName                = $i.buildPartnerName
            }

            if ($i.deploymentType) {
                $hash.DeploymentType = ConvertTo-JiraEnum -Type ([AtlassianPS.JiraPS.DeploymentType]) -Value $i.deploymentType
            }
            if ($i.serverTimeZone) {
                $hash.ServerTimeZone = [AtlassianPS.JiraPS.ServerTimeZone]@{
                    Id          = $i.serverTimeZone.id
                    DisplayName = $i.serverTimeZone.displayName
                }
            }
            if ($i.defaultLocale) {
                $hash.DefaultLocale = [AtlassianPS.JiraPS.ServerLocale]@{
                    Locale = $i.defaultLocale.locale
                }
            }
            if ($null -ne $i.versionNumbers) { $hash.VersionNumbers = [int[]]@($i.versionNumbers) }

            [AtlassianPS.JiraPS.ServerInfo]$hash
        }
    }
}
