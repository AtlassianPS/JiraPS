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

        [string]
        $Name = "Default"
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {

        if (-not $Server.AbsolutePath.EndsWith("/")) {
            $Server = New-Object -TypeName uri -ArgumentList $Server,($Server.AbsolutePath + "/")
        }

        $config = New-Object psobject -Property @{ Server = $Server.ToString() }

        $script:JiraServerConfigs | Add-Member -NotePropertyName $Name -NotePropertyValue $config -Force
        $script:JiraServerConfigs | ConvertTo-Json | Set-Content -Path $script:serversConfig
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
