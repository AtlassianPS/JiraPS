function Get-JiraConfigServer {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
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
            $exception = ([System.IO.FileNotFoundException]"Could not find $ConfigFile")
            $errorId = 'ConfigFile.NotFound'
            $errorCategory = 'ObjectNotFound'
            $errorTarget = $ConfigFile
            $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
            $errorItem.ErrorDetails = "Config file [$ConfigFile] does not exist. Use Set-JiraConfigServer first to define the configuration file."
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

        $xml = New-Object -TypeName XML
        $xml.Load($ConfigFile)

        $xmlConfig = $xml.DocumentElement
        if ($xmlConfig.LocalName -ne 'Config') {
            $exception = ([System.IO.FileFormatException]"XML had not the expected format")
            $errorId = 'ConfigFile.UnexpectedElement'
            $errorCategory = ParserError
            $errorTarget = $ConfigFile
            $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
            $errorItem.ErrorDetails = "Unexpected document element [$($xmlConfig.LocalName)] in configuration file [$ConfigFile]. You may need to delete the config file and recreate it using Set-JiraConfigServer."
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

        if ($xmlConfig.Server) {
            Write-Output $xmlConfig.Server
        }
        else {
            $exception = ([System.UriFormatException]"Could not find URI")
            $errorId = 'ConfigFile.EmptyElement'
            $errorCategory = OpenError
            $errorTarget = $ConfigFile
            $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
            $errorItem.ErrorDetails = "No Server element is defined in the config file.  Use Set-JiraConfigServer to define one."
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
