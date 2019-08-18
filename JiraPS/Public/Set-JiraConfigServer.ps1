function Set-JiraConfigServer {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [Alias('Uri')]
        [Uri]
        $Server,

        [Parameter( Mandatory )]
        [string]
        $Name = "Default"
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {

        $script:JiraServerConfigs[$Name] = New-Object psobject -Property @{ Server = $Server }

        $script:JiraServerConfigs | ConvertTo-Json | Set-Content -Path $script:serversConfig
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
