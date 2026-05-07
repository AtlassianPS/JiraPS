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
                BaseURL                         = ConvertTo-JiraUriValue $i.baseUrl
                Version                         = $i.version
                DeploymentType                  = if ($i.deploymentType) { $i.deploymentType } else { 'Server' }
                BuildNumber                     = $i.buildNumber
                BuildDate                       = ConvertTo-JiraDateTimeOffsetValue $i.buildDate
                ServerTime                      = ConvertTo-JiraDateTimeOffsetValue $i.serverTime
                ScmInfo                         = $i.scmInfo
                ServerTitle                     = $i.serverTitle
                DisplayUrl                      = ConvertTo-JiraUriValue $i.displayUrl
                DisplayUrlConfluence            = ConvertTo-JiraUriValue $i.displayUrlConfluence
                DisplayUrlServicedeskHelpCenter = ConvertTo-JiraUriValue $i.displayUrlServicedeskHelpCenter
                BuildPartnerName                = $i.buildPartnerName
                ServerTimeZone                  = $i.serverTimeZone
                DefaultLocale                   = $i.defaultLocale
            }

            if ($i.versionNumbers) {
                $hash.VersionNumbers = [int[]]@($i.versionNumbers)
            }

            [AtlassianPS.JiraPS.ServerInfo]$hash
        }
    }
}
