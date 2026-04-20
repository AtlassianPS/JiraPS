function Expand-Result {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        $InputObject
    )

    process {
        foreach ($container in $script:PagingContainers) {
            if ($InputObject -and $InputObject.PSObject.Properties[$container]) {
                Write-DebugMessage "Extracting data from [$container] containter"
                $InputObject.$container
            }
        }
    }
}
