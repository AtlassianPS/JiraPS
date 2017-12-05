function Get-JiraSession {
    <#
    .Synopsis
       Obtains a reference to the currently saved JIRA session
    .DESCRIPTION
       This functio obtains a reference to the currently saved JIRA session.  This can provide
       a JIRA session ID, as well as the username used to connect to JIRA.
    .EXAMPLE
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Get-JiraSession
       Creates a Jira session for jiraUsername, then obtains a reference to it.
    .INPUTS
       None
    .OUTPUTS
       [JiraPS.Session] An object representing the Jira session
    #>
    [CmdletBinding()]
    param()

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($MyInvocation.MyCommand.Module.PrivateData -and $MyInvocation.MyCommand.Module.PrivateData.Session) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using Session saved in PrivateData"
            Write-Output $MyInvocation.MyCommand.Module.PrivateData.Session
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
