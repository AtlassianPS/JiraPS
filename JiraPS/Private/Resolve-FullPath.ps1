function Resolve-FullPath {
    [CmdletBinding()]
    param (
        # Path to be resolved.
        # Can be realtive or absolute.
        # Resolves PSDrives
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (-not (Test-Path $_ -PathType Leaf)) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"File not found"),
                        'ParameterValue.FileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $_
                    )
                    $errorItem.ErrorDetails = "No file could be found with the provided path '$_'."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else {
                    return $true
                }
            }
        )]
        [Alias( 'FullName', 'PSPath' )]
        [String]
        $Path
    )

    process {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Resolving path $Path"
        $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
    }
}
