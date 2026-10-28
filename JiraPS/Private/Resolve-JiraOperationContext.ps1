function Resolve-JiraOperationContext {
    <#
    .SYNOPSIS
        Resolve an explicit or default Jira connection without authentication overrides.
    #>
    [CmdletBinding()]
    [OutputType( [AtlassianPS.Connection] )]
    param(
        [Parameter( Mandatory )]
        [System.Collections.IDictionary]
        $BoundParameters
    )

    $selection = @{ Product = 'Jira' }
    foreach ($key in @('Connection', 'ConnectionName')) {
        if ($BoundParameters.Keys -contains $key) { $selection[$key] = $BoundParameters[$key] }
    }

    AtlassianPS.Configuration\Resolve-AtlassianRequestContext @selection
}
