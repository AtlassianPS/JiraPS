function Get-JiraSession
{
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
