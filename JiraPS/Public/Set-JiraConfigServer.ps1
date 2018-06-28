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
            $exception = ([System.ArgumentException]"Invalid Document")
            $errorId = 'InvalidObject.InvalidDocument'
            $errorCategory = 'InvalidData'
            $errorTarget = $_
            $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
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
