function Get-JiraSession {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param()

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($MyInvocation.MyCommand.Module.PrivateData -and $MyInvocation.MyCommand.Module.PrivateData.Session) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using Session saved in PrivateData"
            Write-Output $MyInvocation.MyCommand.Module.PrivateData.Session
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
