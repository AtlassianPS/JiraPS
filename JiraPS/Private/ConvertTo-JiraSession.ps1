function ConvertTo-JiraSession {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline, Position = 0, ParameterSetName = "ByInputObject" )]
        [psobject]
        $InputObject,

        [Parameter( Mandatory )]
        [string]
        $Name,

        [Parameter( Mandatory )]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter( Mandatory )]
        [psobject]
        $ServerConfig
    )

    process {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

        if ("JiraPS.Session" -in $InputObject.TypeNames) {
            Write-Object $InputObject
            return
        }

        if ($InputObject -is [string]) {

            if (-not $script:JiraSessions.ContainsKey($InputObject)) {
                $exception = ([System.InvalidOperationException]"Can not find $name session!")
                $errorId = 'JiraSession.NotFound'
                $errorCategory = 'InvalidOperation'
                $errorTarget = $_
                $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                $errorItem.ErrorDetails = "Wrong value for InputObject parameter provided. Use New-JiraSession to solve the problem."
                $PSCmdlet.ThrowTerminatingError($errorItem)
            }

            Write-Object $script:JiraSessions[$InputObject]
            return
        }

        $webSession = New-Object -TypeName Microsoft.PowerShell.Commands.WebRequestSession

        if ($InputObject -is [Microsoft.PowerShell.Commands.WebRequestSession]) {
            $webSession = [Microsoft.PowerShell.Commands.WebRequestSession]$InputObject
        }

        if (-not $Credential -and $Credential -ne [pscredential]::Empty -and $InputObject -is [pscredential]) {
            $Credential = $InputObject
        }

        $webSession.Credentials = $Credential

        $props = @{
            Name = "Default"
            WebSession = $webSession
            ServerConfig = $null
        }

        $result = New-Object -TypeName PSObject -Property $props
        $result.PSObject.TypeNames.Insert(0, 'JiraPS.Session')
        $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
            Write-Output "JiraSession[JSessionID=$($this.JSessionID)]"
        }

        Write-Output $result
    }
}
