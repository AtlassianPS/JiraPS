function Remove-JiraSession {
    <#
    .Synopsis
       Removes a persistent JIRA authenticated session
    .DESCRIPTION
       This function removes a persistent JIRA authenticated session and closes the session for JIRA.
       This can be used to "log out" of JIRA once work is complete.

       If called with the Session parameter, this function will attempt to close the provided
       JiraPS.Session object.

       If called with no parameters, this function will close the saved JIRA session in the module's
       PrivateData.
    .EXAMPLE
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Get-JiraIssue TEST-01
       Remove-JiraSession
       This example creates a JIRA session for jiraUsername, runs Get-JiraIssue, and closes the JIRA session.
    .EXAMPLE
       $s = New-JiraSession -Credential (Get-Credential jiraUsername)
       Remove-JiraSession $s
       This example creates a JIRA session and saves it to a variable, then uses the variable reference to
       close the session.
    .INPUTS
       [JiraPS.Session] A Session object to close.
    .OUTPUTS
       [JiraPS.Session] An object representing the Jira session
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        # A Jira session to be closed. If not specified, this function will use a saved session.
        [Parameter( ValueFromPipeline )]
        [Object]
        $Session
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($Session) {
            if ((Get-Member -InputObject $Session).TypeName -ne 'JiraPS.Session') {
                throw "Unable to parse parameter [$Session] as a JiraPS.Session object"
            }
        }
        else {
            $Session = Get-JiraSession
        }

        if ($Session) {
            $MyInvocation.MyCommand.Module.PrivateData.Session = $null
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
