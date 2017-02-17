function Export-JiraConfigServerModulePrivateData
{
    <#
    .Synopsis
       Writes the configured URL for the JIRA server to memory
    .DESCRIPTION
       Writes to $MyInvocation.MyCommand.Module.PrivateData
    .EXAMPLE
       Export-JiraConfigServerModulePrivateData -Server $Server
    .INPUTS
       This function does not accept pipeline input.
    #>
    [CmdletBinding()]
    param(
        # The base URL of the Jira instance.
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('Uri')]
        [String] $Server
    )
    if (-not $MyInvocation.MyCommand.Module.PrivateData)
    {
        $MyInvocation.MyCommand.Module.PrivateData = @{}
    }
    $MyInvocation.MyCommand.Module.PrivateData.ActiveConfigServer = $Server
}