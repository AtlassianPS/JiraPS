function Remove-JiraIssueAttachment
{<#
    .Synopsis
       Removes an attachment from a JIRA issue
    .DESCRIPTION
       This function removes an attachment from a JIRA issue.
    .EXAMPLE
       Remove-JiraIssueAttachment -AttachmentId 10039
       Removes attachment with id of 10039

    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
                   ConfirmImpact = 'High')]
    param(
        # Id of the Attachment to delete
        [Parameter(Mandatory = $true)]
        [Int[]] $attachId,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential,

        [Switch] $force
    )

    Begin
    {
        Write-Debug "[Remove-JiraGroupMember] Reading information from config file"
        try
        {
            Write-Debug "[Remove-JiraGroupMember] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Remove-JiraGroupMember] Encountered an error reading configuration data."
            throw $err
        }

        $restUrl = "$server/rest/api/latest/attachment/"

        if ($Force)
        {
            Write-Debug "[Remove-JiraGroupMember] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    Process
    {
            foreach ($a in $attachId)
            {
                If ($PSCmdlet.ShouldProcess($attachId, "Removing attachment with ID $attachId")) {
                    $thisUrl = "$restUrl"+"$a"
                    Write-Debug "[Remove-JiraIssueAttachment] RemoteLink URL: [$thisUrl]"

                    Write-Debug "[Remove-JiraIssueAttachment] Preparing for blastoff!"
                    Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
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

        Write-Debug "[Remove-JiraIssueAttachment] Complete"
    }
}