function Get-JiraServerInformation {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/2/serverInfo"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $parameter = @{
            URI                = $resourceURi
            Method             = "GET"
            Credential         = $Credential
            CacheKey           = 'ServerInfo'
            CacheExpiryMinutes = 5
            BypassCache        = $Force
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

        try {
            $result = Invoke-JiraMethod @parameter
            Write-Output (ConvertTo-JiraServerInfo -InputObject $result)
        }
        catch {
            Write-Warning "[$($MyInvocation.MyCommand.Name)] Could not retrieve server information: $_"
            $fallback = [PSCustomObject]@{
                PSTypeName     = 'JiraPS.ServerInfo'
                DeploymentType = 'Server'
            }
            Write-Output $fallback
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}

New-Alias -Name "Get-JiraServerInfo" -Value "Get-JiraServerInformation" -ErrorAction SilentlyContinue
