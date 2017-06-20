function Remove-JiraIssueAttachment
{<#
    .Synopsis
       Removes a remote link from a JIRA issue
    .DESCRIPTION
       This function removes a remote link from a JIRA issue.
    .EXAMPLE
       Remove-JiraIssueAttachment -AttachmentId 10039
       Removes attachment with id of 10039
    .INPUTS
       [PSJira.Issue[]] The JIRA issue from which to delete a link
    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
                   ConfirmImpact = 'High')]
    param(
        # Issue to which to attach the file
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Key')]
        [Object] $Issue,

        # Id of the remote link to delete
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
            # Validate input object
            if (
                # from Pipeline
                (($_) -and ($_.PSObject.TypeNames[0] -ne "PSJira.Issue")) -or
                # by parameter
                ($Issue.PSObject.TypeNames[0] -ne "PSJira.Issue") -and (($Issue -isnot [String]))
            ) {
                $message = "Wrong object type provided for Issue. Was $($Issue.Gettype().Name)"
                $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
                Throw $exception
            }

            # As we are not able to use proper type casting in the parameters, this is a workaround
            # to extract the data from a PSJira.Issue object
            Write-Debug "[Remove-JiraIssueAttachment] Obtaining a reference to Jira issue [$Issue]"
            if ($Issue.PSObject.TypeNames[0] -eq "PSJira.Issue" -and $Issue.RestURL) {
                $issueObj = $Issue
            }
            else {
                $issueObj = Get-JiraIssue -InputObject $Issue -Credential $Credential -ErrorAction Stop
            }

            $ID = $issueObj.ID


            foreach ($a in $attachId)
            {

                $thisUrl = "$restUrl"+"$a"
                Write-Debug "[Remove-JiraIssueAttachment] RemoteLink URL: [$thisUrl]"

                Write-Debug "[Remove-JiraIssueAttachment] Preparing for blastoff!"
                Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
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