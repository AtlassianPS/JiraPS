function Get-JiraSession {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType([AtlassianPS.Connection])]
    param(
        [String]$Name,

        [Int]$Id,

        [Switch]$Default
    )

    Get-JiraConnection @PSBoundParameters
}
