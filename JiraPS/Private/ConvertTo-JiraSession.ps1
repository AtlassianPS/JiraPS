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
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Building AtlassianPS.JiraPS.Session"

        $hash = @{
            WebSession = $Session
        }

        if ($Username) {
            $hash.Username = $Username
        }

        [AtlassianPS.JiraPS.Session]$hash
    }
}
