function Get-JiraConnection {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType( [AtlassianPS.Connection] )]
    param(
        [String]
        $Name,

        [Int]
        $Id,

        [Switch]
        $Default
    )

    AtlassianPS.Configuration\Get-AtlassianConnection -Product Jira @PSBoundParameters
}
