function Get-JiraConfigServer
{
    <#
    .Synopsis
       Obtains the configured URL for the JIRA server
    .DESCRIPTION
       This function returns the configured URL for the JIRA server that PSJira should manipulate. By default, this is stored in a config.xml file at the module's root path.
    .EXAMPLE
       Get-JiraConfigServer
       Returns the server URL of the JIRA server configured in the PSJira config file.
    .EXAMPLE
       Get-JiraConfigServer -ConfigFile C:\jiraconfig.xml
       Returns the server URL of the JIRA server configured at C:\jiraconfig.xml.
    .INPUTS
       This function does not accept pipeline input.
    .OUTPUTS
       [System.String]
    .NOTES
       Support for multiple configuration files is limited at this point in time, but enhancements are planned for a future update.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        # Path to the configuration file, if not the default.
        [String] $ConfigFile
    )

    Import-JiraConfigServerXml -ConfigFile $ConfigFile
}
