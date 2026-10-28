function Write-DebugMessage {
    [CmdletBinding( DefaultParameterSetName = 'Message' )]
    param(
        [Parameter( Position = 0, ValueFromPipeline, ParameterSetName = 'Message' )]
        [String]
        $Message,

        [Parameter( Mandatory, ParameterSetName = 'BoundParameters' )]
        [System.Collections.IDictionary]
        $BoundParameters,

        [System.Management.Automation.PSCmdlet]
        $Cmdlet = (Get-Variable -Scope 1 -Name PSCmdlet -ValueOnly)
    )

    begin {
        $oldDebugPreference = $DebugPreference
        if (-not ($DebugPreference -eq "SilentlyContinue")) { $DebugPreference = 'Continue' }
    }

    process {
        $parameters = @{} + $PSBoundParameters
        $parameters['Cmdlet'] = $Cmdlet
        $parameters['Debug'] = $DebugPreference -ne 'SilentlyContinue'
        AtlassianPS.Configuration\Write-AtlassianDebugMessage @parameters
    }

    end {
        $DebugPreference = $oldDebugPreference
    }
}
