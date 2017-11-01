function ConvertTo-JiraServerInfo {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true
        )]
        [PSObject[]] $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $props = @{
                'BaseURL'        = $i.baseUrl
                # With PoSh v6, the version shall be casted to [SemanticVersion]
                'Version'        = $i.version
                'DeploymentType' = $i.deploymentType
                'BuildNumber'    = $i.buildNumber
                'BuildDate'      = Get-Date $i.buildDate
                'ServerTime'     = Get-Date $i.serverTime
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
