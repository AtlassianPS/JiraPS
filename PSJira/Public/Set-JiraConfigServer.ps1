function Set-JiraConfigServer
{
    <#
    .Synopsis
       Defines the configured URL for the JIRA server
    .DESCRIPTION
       This function defines the configured URL for the JIRA server that PSJira should manipulate. By default, this is stored in a config.xml file at the module's root path.
    .EXAMPLE
       Set-JiraConfigServer 'https://jira.example.com:8080'
       This example defines the server URL of the JIRA server configured in the PSJira config file.
    .EXAMPLE
       Set-JiraConfigServer -Server 'https://jira.example.com:8080' -ConfigFile C:\jiraconfig.xml
       This example defines the server URL of the JIRA server configured at C:\jiraconfig.xml.
    .INPUTS
       This function does not accept pipeline input.
    .OUTPUTS
       [System.String]
    .NOTES
       Support for multiple configuration files is limited at this point in time, but enhancements are planned for a future update.
    #>
    [CmdletBinding()]
    param(
        # The base URL of the Jira instance.
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('Uri')]
        [String] $Server,

        [String] $ConfigFile
    )

    Export-JiraConfigServerXml -Server $Server -ConfigFile $ConfigFile
}


