function Remove-JiraSession {
    # .ExternalHelp ..\JiraPS-help.xml
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Compatibility wrapper delegates WhatIf and Confirm to Disconnect-Jira.')]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object')]
        [Alias('Session')]
        [AtlassianPS.Connection]$Connection,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [String]$Name,

        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [Int]$Id,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Switch]$All
    )

    process { Disconnect-Jira @PSBoundParameters }
}
