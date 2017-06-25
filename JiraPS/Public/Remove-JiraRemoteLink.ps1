function Remove-JiraRemoteLink
{
    <#
    .Synopsis
       Removes a remote link from a JIRA issue
    .DESCRIPTION
       This function removes a remote link from a JIRA issue.
    .EXAMPLE
       Remove-JiraRemoteLink Project1-1001 10000,20000
       Removes two remote link from issue "Project1-1001"
    .EXAMPLE
       Get-JiraIssue -Query "project = Project1" | Remove-JiraRemoteLink 10000
       Removes a specific remote link from all issues in project "Project1"
    .INPUTS
       [JiraPS.Issue[]] The JIRA issue from which to delete a link
    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]
    param(
        # Issue from which to delete a remote link.
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true,
            Position = 0
        )]
        [Alias("Key")]
        [Object[]] $Issue,

        # Id of the remote link to delete.
        [Parameter(Mandatory = $true)]
        [Int[]] $LinkId,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential,

        # Suppress user confirmation.
        [Switch] $Force
    )

    Begin
    {
        try
        {
            Write-Debug "[Remove-JiraRemoteLink] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch
        {
            $err = $_
            Write-Debug "[Remove-JiraRemoteLink] Encountered an error reading configuration data."
            throw $err
        }

        $restUrl = "$server/rest/api/latest/issue/{0}/remotelink/{1}"

        if ($Force)
        {
            Write-Debug "[Remove-JiraRemoteLink] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    Process
    {

        foreach ($k in $Issue)
        {
            Write-Debug "[Remove-JiraRemoteLink] Processing issue key [$k]"
            $issueObj = Get-JiraIssue $k -Credential $Credential

            foreach ($l in $LinkId)
            {
                $thisUrl = $restUrl -f $k, $l
                Write-Debug "[Remove-JiraRemoteLink] RemoteLink URL: [$thisUrl]"

                Write-Debug "[Remove-JiraRemoteLink] Checking for -WhatIf and Confirm"
                if ($PSCmdlet.ShouldProcess($issueObj.Key, "Remove RemoteLink from [$issueObj] from JIRA"))
                {
                    Write-Debug "[Remove-JiraRemoteLink] Preparing for blastoff!"
                    Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
                }
                else
                {
                    Write-Debug "[Remove-JiraRemoteLink] Runnning in WhatIf mode or user denied the Confirm prompt; no operation will be performed"
                }
            }
        }
    }

    End
    {
        if ($Force)
        {
            Write-Debug "[Remove-JiraGroupMember] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Debug "[Remove-JiraRemoteLink] Complete"
    }
}
