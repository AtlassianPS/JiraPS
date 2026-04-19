function ConvertTo-JiraServerInfo {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $props = @{
                'BaseURL'        = $i.baseUrl
                'Version'        = $i.version
                'DeploymentType' = if ($i.deploymentType) { $i.deploymentType } else { 'Server' }
                'BuildNumber'    = $i.buildNumber
                'BuildDate'      = if ($i.buildDate) { Get-Date $i.buildDate } else { $null }
                'ServerTime'     = if ($i.serverTime) { Get-Date $i.serverTime } else { $null }
                'ScmInfo'        = $i.scmInfo
                'ServerTitle'    = $i.serverTitle
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.ServerInfo')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "[$($this.DeploymentType)] $($this.Version)"
            }

            Write-Output $result
        }
    }
}
