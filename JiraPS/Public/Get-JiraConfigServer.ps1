function Get-JiraConfigServer {
    <#
    .SYNOPSIS
       Obtains the configured URL for the JIRA server
    .DESCRIPTION
       This function returns the configured URL for the JIRA server that JiraPS should manipulate. By default, this is stored in a config.xml file at the module's root path.
    .EXAMPLE
       Get-JiraConfigServer
       Returns the server URL of the JIRA server configured in the JiraPS config file.
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

        if (-not (Test-Path -Path $ConfigFile)) {
            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                ([System.IO.FileNotFoundException]"Could not find $ConfigFile"),
                'ConfigFile.NotFound',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $ConfigFile
            )
            $errorItem.ErrorDetails = "Config file [$ConfigFile] does not exist. Use Set-JiraConfigServer first to define the configuration file."
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

        Write-Debug "Loading config file `$ConfigFile [$ConfigFile]"
        $xml = New-Object -TypeName XML
        $xml.Load($ConfigFile)

        $xmlConfig = $xml.DocumentElement
        if ($xmlConfig.LocalName -ne 'Config') {
            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                ([System.IO.FileFormatException]"XML had not the expected format"),
                'ConfigFile.UnexpectedElement',
                [System.Management.Automation.ErrorCategory]::ParserError,
                $ConfigFile
            )
            $errorItem.ErrorDetails = "Unexpected document element [$($xmlConfig.LocalName)] in configuration file [$ConfigFile]. You may need to delete the config file and recreate it using Set-JiraConfigServer."
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

        if ($xmlConfig.Server) {
            Write-Output $xmlConfig.Server
        }
        else {
            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                ([System.UriFormatException]"Could not find URI"),
                'ConfigFile.EmptyElement',
                [System.Management.Automation.ErrorCategory]::OpenError,
                $ConfigFile
            )
            $errorItem.ErrorDetails = "No Server element is defined in the config file.  Use Set-JiraConfigServer to define one."
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
