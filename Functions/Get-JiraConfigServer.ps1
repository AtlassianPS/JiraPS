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

    # Using a default value for this parameter wouldn't handle all cases. We want to make sure 
    # that the user can pass a $null value to the ConfigFile parameter...but if it's null, we 
    # want to default to the script variable just as we would if the parameter was not 
    # provided at all.

    if (-not ($ConfigFile))
    {
#        Write-Debug "[Get-JiraConfigServer] ConfigFile was not provided, or provided with a null value"
        # This file should be in $moduleRoot/Functions/Internal, so PSScriptRoot will be $moduleRoot/Functions
        $moduleFolder = Split-Path -Path $PSScriptRoot -Parent
#        Write-Debug "[Get-JiraConfigServer] Module folder: $moduleFolder"
        $ConfigFile = Join-Path -Path $moduleFolder -ChildPath 'config.xml'
#        Write-Debug "[Get-JiraConfigServer] Using default config file at [$ConfigFile]"
    }

    if (-not (Test-Path -Path $ConfigFile))
    {
        throw "Config file [$ConfigFile] does not exist. Use Set-JiraConfigServer first to define the configuration file."
    }

#    Write-Debug "Loading config file '$ConfigFile'"
    $xml = New-Object -TypeName XML
    $xml.Load($ConfigFile)

    $xmlConfig = $xml.DocumentElement
    if ($xmlConfig.LocalName -ne 'Config')
    {
        throw "Unexpected document element [$($xmlConfig.LocalName)] in configuration file [$ConfigFile]. You may need to delete the config file and recreate it using Set-JiraConfigServer."
    }

#    Write-Debug "[Get-JiraConfigServer] Checking for Server element"
    if ($xmlConfig.Server)
    {
#        Write-Debug "[Get-JiraConfigServer] Found Server element. Outputting."
        Write-Output $xmlConfig.Server
    } else {
#        Write-Debug "[Get-JiraConfigServer] No Server element is defined in the config file.  Throwing exception."
        throw "No Server element is defined in the config file.  Use Set-JiraConfigServer to define one."
    }

#    Write-Debug "[Get-JiraConfigServer] Complete."
}