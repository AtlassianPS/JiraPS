function Expand-Result {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        $InputObject
    )

    process {
        $foundContainer = $false
        foreach ($container in $script:PagingContainers) {
            if (($InputObject) -and ($InputObject | Get-Member -Name $container)) {
                Write-DebugMessage "Extracting data from [$container] container"
                $foundContainer = $true
                $InputObject.$container
                return
            }
        }

        # If no container found, log available properties for debugging
        if (-not $foundContainer -and $InputObject) {
            $props = ($InputObject | Get-Member -MemberType Properties).Name -join ', '
            Write-DebugMessage "No paging container found. Available properties: $props"
            Write-DebugMessage "Expected containers: $($script:PagingContainers -join ', ')"
        }
    }
}
