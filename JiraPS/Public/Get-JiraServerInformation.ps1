function Get-JiraServerInformation {
    <#
    .Synopsis
       This function returns the information about the JIRA Server
    .DESCRIPTION
       This functions shows all the information about the JIRA server, such as version, time, etc
    .EXAMPLE
       Get-JiraServerInformation
       This example returns information about the JIRA server.
    .INPUTS

    .OUTPUTS
       [JiraPS.ServerInfo]
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        Write-Debug "[Get-JiraServerInformation] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $url = "$server/rest/api/latest/serverInfo"
    }

    process {
        Write-Debug "[Get-JiraServerInformation] Preparing for blastoff!"
        Invoke-JiraMethod -Method Get -URI $url -Credential $Credential | ConvertTo-JiraServerInfo
    }

    end {
        Write-Debug "[Get-JiraServerInformation] Complete."
    }
}

New-Alias -Name "Get-JiraServerInfo" -Value "Get-JiraServerInformation" -ErrorAction SilentlyContinue
