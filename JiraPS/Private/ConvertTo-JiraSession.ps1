function ConvertTo-JiraSession {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory )]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $Session,

        [String]
        $Username
    )

    process {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

        $props = @{
            'WebSession' = $Session
        }

        if ($Username) {
            $props.Username = $Username
        }

        $result = New-Object -TypeName PSObject -Property $props
        $result.PSObject.TypeNames.Insert(0, 'JiraPS.Session')
        $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
            Write-Output "JiraSession[JSessionID=$($this.JSessionID)]"
        }

        Write-Output $result
    }
}
