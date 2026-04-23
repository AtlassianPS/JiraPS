function ConvertTo-JiraSession {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Session])]
    param(
        [Parameter( Mandatory )]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $Session,

        [String]
        $Username
    )

    process {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

        $result = [AtlassianPS.JiraPS.Session]@{
            WebSession = $Session
        }

        if ($Username) {
            $result.Username = $Username
        }

        Add-LegacyTypeAlias -InputObject $result -LegacyName 'JiraPS.Session'
    }
}
