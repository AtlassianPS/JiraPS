function Get-JiraConfigServer {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [string]
        $Name = "Default"
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (-not $script:JiraServerConfigs.ContainsKey($Name)) {
            $exception = ([System.InvalidOperationException]"Can not find $name configuration!")
            $errorId = 'ConfigServer.NotFound'
            $errorCategory = 'InvalidOperation'
            $errorTarget = $_
            $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
            $errorItem.ErrorDetails = "Wrong value for Name parameter provided. Use Set-JiraConfigServer to solve the problem."
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

        return $script:JiraServerConfigs[$Name]
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
