function Set-TlsLevel {
    [CmdletBinding( SupportsShouldProcess = $false )]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Set')]
        [Switch]$Tls12,

        [Parameter(Mandatory, ParameterSetName = 'Revert')]
        [Switch]$Revert
    )

    begin {
        if ($Tls12) {
            $Script:OriginalTlsSettings = [Net.ServicePointManager]::SecurityProtocol

            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        }
        if ($Revert) {
            if ($Script:OriginalTlsSettings) {
                [Net.ServicePointManager]::SecurityProtocol = $Script:OriginalTlsSettings
            }
        }
    }
}
