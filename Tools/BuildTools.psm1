function Assert-True {
    [CmdletBinding( DefaultParameterSetName = 'ByBool' )]
    param(
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByScriptBlock' )]
        [ScriptBlock]$ScriptBlock,
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByBool' )]
        [Bool]$Bool,
        [Parameter( Position = 1, Mandatory )]
        [String]$Message
    )

    if ($ScriptBlock) {
        $Bool = & $ScriptBlock
    }

    if (-not $Bool) {
        throw $Message
    }
}

Export-ModuleMember -Function Assert-True
