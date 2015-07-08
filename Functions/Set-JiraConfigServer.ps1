function Set-JiraConfigServer
{
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

    # Using a default value for this parameter wouldn't handle all cases. We want to make sure 
    # that the user can pass a $null value to the ConfigFile parameter...but if it's null, we 
    # want to default to the script variable just as we would if the parameter was not 
    # provided at all.

    if (-not ($ConfigFile))
    {
#        Write-Debug "[Set-JiraConfigServer] ConfigFile was not provided, or provided with a null value"
        # This file should be in $moduleRoot/Functions/Internal, so PSScriptRoot will be $moduleRoot/Functions
        $moduleFolder = Split-Path -Path $PSScriptRoot -Parent
#        Write-Debug "[Set-JiraConfigServer] Module folder: $moduleFolder"
        $ConfigFile = Join-Path -Path $moduleFolder -ChildPath 'config.xml'
#        Write-Debug "[Set-JiraConfigServer] Using default config file at [$ConfigFile]"
    }

    if (-not (Test-Path -Path $ConfigFile))
    {
#        Write-Debug "[Set-JiraConfigServer] Creating config file '$ConfigFile'"
        $xml = [XML] '<Config></Config>'
        
    } else {
#        Write-Debug "[Set-JiraConfigServer] Loading config file '$ConfigFile'"
        $xml = New-Object -TypeName XML
        $xml.Load($ConfigFile)
    }
    
    $xmlConfig = $xml.DocumentElement
    if ($xmlConfig.LocalName -ne 'Config')
    {
        throw "Unexpected document element [$($xmlConfig.LocalName)] in configuration file. You may need to delete the config file and recreate it using this function."
    }

    if ($xmlConfig.Server)
    {
#        Write-Debug "[Set-JiraConfigServer] Changing the existing Server element to the provided value '$Server'"
        $xmlConfig.Server = $Server
    } else {
#        Write-Debug "[Set-JiraConfigServer] Creating new element Server"
        $xmlServer = $xml.CreateElement('Server')
#        Write-Debug "[Set-JiraConfigServer] Writing InnerText property with provided value '$Server'"
        $xmlServer.InnerText = $Server
#        Write-Debug "[Set-JiraConfigServer] Adding element to existing XML file"
        [void] $xmlConfig.AppendChild($xmlServer)
    }
    
#    Write-Debug "[Set-JiraConfigServer] Saving XML file"
    try
    {
        $xml.Save($ConfigFile)
    } catch {
        $err = $_
#        Write-Debug "[Set-JiraConfigServer] Encountered an error saving the XML file"
#        Write-Debug "[Set-JiraConfigServer] Throwing exception"
        throw $err
    }
#    Write-Debug "[Set-JiraConfigServer] Complete"

}