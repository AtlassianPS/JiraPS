function Remove-JiraSession {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [Parameter( ValueFromPipeline )]
        [Object]
        $Session
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $sessionName = $null

        if ("JiraPS.Session" -in $Session.PSObject.TypeNames) {
            $sessionName = $Session.Name
        }

        if ($Session -is [string]) {
            $sessionName = $Session
        }

        if (-not $Session) {
            $sessionName = "Default"
        }

        if ($sessionName -and $script:JiraSessions.ContainsKey($sessionName)) {
            $script:JiraSessions.Remove($sessionName)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
