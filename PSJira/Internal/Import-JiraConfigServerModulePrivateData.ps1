function Import-JiraConfigServerModulePrivateData
{
    <#
    .Synopsis
       Reads JiraConfigServer from memory
    .DESCRIPTION
       Reads from $MyInvocation.MyCommand.Module.PrivateData
    .EXAMPLE
       Import-JiraConfigServerModulePrivateData
    .OUTPUTS
       [System.String]
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
    )
    if (-not $MyInvocation.MyCommand.Module.PrivateData)
    {
        $MyInvocation.MyCommand.Module.PrivateData = @{}
    }
    if ($MyInvocation.MyCommand.Module.PrivateData.ActiveConfigServer)
    {
        $ActiveConfigServer = $MyInvocation.MyCommand.Module.PrivateData.ActiveConfigServer
        Write-Output $ActiveConfigServer
    }
}
