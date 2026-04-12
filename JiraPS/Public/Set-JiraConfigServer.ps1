function Set-JiraConfigServer {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [Alias('Uri')]
        [Uri]
        $Server
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        if (-not($Server.IsAbsoluteUri)) {
            throw "Server must be an absolute URI (e.g., https://jira.domain.com/)"
        }
    }

    process {
        $script:JiraServerUrl = $Server
        $script:JiraServerInfo = $null

        Set-Content -Value $Server -Path "$script:serverConfig"
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
