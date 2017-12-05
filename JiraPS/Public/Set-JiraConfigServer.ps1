function Set-JiraConfigServer {
    <#
    .Synopsis
       Defines the configured URL for the JIRA server
    .DESCRIPTION
       This function defines the configured URL for the JIRA server that JiraPS should manipulate. By default, this is stored in a config.xml file at the module's root path.
    .EXAMPLE
       Set-JiraConfigServer 'https://jira.example.com:8080'
       This example defines the server URL of the JIRA server configured in the JiraPS config file.
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
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        # The base URL of the Jira instance.
        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [Alias('Uri')]
        [Uri]
        $Server,

        # Path where the file with the configuration will be stored.
        [String]
        $ConfigFile
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Using a default value for this parameter wouldn't handle all cases. We want to make sure
        # that the user can pass a $null value to the ConfigFile parameter...but if it's null, we
        # want to default to the script variable just as we would if the parameter was not
        # provided at all.

        if (-not ($ConfigFile)) {
            # This file should be in $moduleRoot/Functions/Internal, so PSScriptRoot will be $moduleRoot/Functions
            $moduleFolder = Split-Path -Path $PSScriptRoot -Parent
            $ConfigFile = Join-Path -Path $moduleFolder -ChildPath 'config.xml'
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Config file path: $ConfigFile"
        if (-not (Test-Path -Path $ConfigFile)) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Creating new Config file"
            $xml = [XML] '<Config></Config>'
        }
        else {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Using existing Config file"
            $xml = New-Object -TypeName XML
            $xml.Load($ConfigFile)
        }

        $xmlConfig = $xml.DocumentElement
        if ($xmlConfig.LocalName -ne 'Config') {
            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                ([System.ArgumentException]"Invalid Document"),
                'InvalidObject.InvalidDocument',
                [System.Management.Automation.ErrorCategory]::InvalidData,
                $_
            )
            $errorItem.ErrorDetails = "Unexpected document element [$($xmlConfig.LocalName)] in configuration file. You may need to delete the config file and recreate it using this function."
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

        $fixedServer = $Server.AbsoluteUri.Trim('/')

        if ($xmlConfig.Server) {
            $xmlConfig.Server = $fixedServer
        }
        else {
            $xmlServer = $xml.CreateElement('Server')
            $xmlServer.InnerText = $fixedServer
            [void] $xmlConfig.AppendChild($xmlServer)
        }

        try {
            $xml.Save($ConfigFile)
        }
        catch {
            throw $_
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
