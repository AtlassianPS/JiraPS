function New-JiraSession {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [Parameter( Mandatory )]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Hashtable]
        $Headers = @{},

        [string]
        $SessionName = "Default",

        [string]
        $ServerName = "Default"
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $serverConfig = Get-JiraConfigServer -Name $ServerName

        $resourceURi = "rest/api/2/mypermissions"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $session = ConvertTo-JiraSession -Name $SessionName -Credential $Credential -ServerConfig $serverConfig

        $parameter = @{
            URI          = $resourceURi
            Method       = "GET"
            Headers      = $Headers
            Session      = $session
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

        Invoke-JiraMethod @parameter | Out-Null

        $script:JiraSessions[$SessionName] = $session

        Write-Output $session
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
