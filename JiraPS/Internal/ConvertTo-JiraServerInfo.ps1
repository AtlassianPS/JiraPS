function ConvertTo-JiraServerInfo {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [PSObject[]] $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            # Write-Debug "Processing object: '$i'"

            # Write-Debug "Defining standard properties"
            $props = @{
                'BaseURL'        = $i.baseUrl
                # With PoSh v6, the version shall be casted to [SemanticVersion]
                'Version'        = $i.version
                'DeploymentType' = $i.deploymentType
                'BuildNumber'    = $i.buildNumber
                'BuildDate'      = (Get-Date $i.buildDate)
                'ServerTime'     = (Get-Date $i.serverTime)
                'ScmInfo'        = $i.scmInfo
                'ServerTitle'    = $i.serverTitle
            }

            # Write-Debug "Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props

            # Write-Debug "Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.ServerInfo')

            # Write-Debug "[ConvertTo-JiraProject] Inserting custom toString() method"
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "[$($this.DeploymentType)] $($this.Version)"
            }

            # Write-Debug "Outputting object"
            Write-Output $result
        }
    }

    end {
        # Write-Debug "Complete"
    }
}
