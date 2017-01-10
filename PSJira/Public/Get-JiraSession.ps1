function Get-JiraSession
{
    <#
    .Synopsis
       Obtains a references to saved JIRA sessions
    .DESCRIPTION
       This function obtains references to saved JIRA sessions. This can provide
       a JIRA session ID, the server and the username used to connect to JIRA.
    .EXAMPLE
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Get-JiraSession
       Creates a Jira session for jiraUsername, then obtains a reference to it.
    .EXAMPLE
       Set-JiraConfigServer 'http://jira1.example.com'
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Set-JiraConfigServer 'http://jira2.example.com'
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Get-JiraSession
       Creates two Jira sessions, then obtains a reference to the 2nd one
    .EXAMPLE
       Set-JiraConfigServer 'http://jira1.example.com'
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Set-JiraConfigServer 'http://jira2.example.com'
       New-JiraSession -Credential (Get-Credential jiraUsername)
       Get-JiraSession -All
       Creates two Jira sessions, then obtains both references
    .INPUTS
       None
    .OUTPUTS
       [PSJira.Session] An object representing the Jira session
    #>
    [CmdletBinding()]
    param(
        [Switch]$All
    )

    begin
    {
        $Server = Get-JiraConfigServer
    }

    process
    {
        if ($MyInvocation.MyCommand.Module.PrivateData)
        {
            Write-Debug "[Get-JiraSession] Module private data exists"
            if ($MyInvocation.MyCommand.Module.PrivateData.Session)
            {
                Write-Debug "[Get-JiraSession] A Session object is saved; outputting"
                if ($All)
                {
                    # We have to store the keys seperately because we cannot delete from a
                    # hashtable while we are itering throug it.
                    $Keys = @($MyInvocation.MyCommand.Module.PrivateData.Session.Keys)
                } else {
                    $Keys = @(Get-JiraConfigServer)
                }
                foreach ($Key in $Keys)
                {
                    Write-Output $MyInvocation.MyCommand.Module.PrivateData.Session[$Key]
                }
            } else {
                Write-Debug "[Get-JiraSession] No Session objects are saved"
                Write-Verbose "No Jira sessions have been saved."
            }
        } else {
            Write-Debug "[Get-JiraSession] No module private data is defined. No saved sessions exist."
            Write-Verbose "No Jira sessions have been saved."
        }
    }
}
