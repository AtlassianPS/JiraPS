function Set-JiraSession {
    # .ExternalHelp ..\JiraPS-help.xml
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Compatibility wrapper selects existing local state without HTTP or persistence.'
    )]
    [CmdletBinding( DefaultParameterSetName = 'Object' )]
    [OutputType( [AtlassianPS.Connection] )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'Object' )]
        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection,

        [Parameter( Mandatory, ParameterSetName = 'Name' )]
        [String]
        $Name,

        [Parameter( Mandatory, ParameterSetName = 'Id' )]
        [Int]
        $Id
    )

    process { Select-JiraConnection @PSBoundParameters }
}
